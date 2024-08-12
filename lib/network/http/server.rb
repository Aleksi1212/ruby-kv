# frozen_string_literal: true

require 'sinatra'
require 'sinatra/namespace'
require 'jwt'
require 'openssl'
require 'securerandom'
require 'date'
require 'base64'

require_relative '../../ruby_kv'
require_relative '../sql/users'

HTTP_PORT = 8080

set :port, HTTP_PORT

DB_STORE = RubyKV::DiskStore.new
USERS_DB = Users.new

JWT.configuration.strict_base64_decoding = true

JWT_RSA_PRIVATE_KEY = OpenSSL::PKey::RSA.generate 2048
JWT_RSA_PUBLIC_KEY = JWT_RSA_PRIVATE_KEY.public_key

SESSION_TOKEN_ALGO = 'RS256'
ACCESS_TOKEN_ALGO = 'HS256'

class Authenticator
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)


    return @app.call(env) if request.path == '/ruby_kv/api/v1/authenticate'

    headers_test = Hash[*env.select { |k, v| k.start_with? 'HTTP_' }
                            .collect { |k, v| [k.sub(/^HTTP_/, ''), v] }
                            .collect { |k, v| [k.split('_').collect(&:capitalize).join('-'), v] }
                            .sort
                            .flatten]

    session_token = request.cookies['session_token']
    access_token = headers_test['Authorization'].sub!('Bearer ', '')

    decoded_session_token = JWT.decode(session_token, JWT_RSA_PUBLIC_KEY, true, { algorithm: SESSION_TOKEN_ALGO })[0]
    decoded_access_token = JWT.decode(access_token, session_token, true, { algorithm: ACCESS_TOKEN_ALGO })[0]

    if decoded_session_token['user_name'] == decoded_access_token['user_name']
      access_token_ttl = Date.parse(decoded_access_token['ttl'])
      if access_token_ttl >= Date.today
        @app.call(env)
      else
        [401, { 'Content-Type' => 'application/json' }, [{ message: 'Access token expired' }.to_json]]
      end
    else
      [401, { 'Content-Type' => 'application/json' }, [{ message: 'Invalid access token' }.to_json]]
    end
  rescue JWT::VerificationError, JWT::DecodeError => e
    [401, { 'Content-Type' => 'application/json' }, [{ message: e.message }.to_json]]
  rescue StandardError => e
    [500, { 'Content-Type' => 'application/json' }, [{ message: e.message }.to_json]]
  end
end

use Authenticator

namespace '/ruby_kv/api/v1' do
  post '/authenticate' do
    content_type :json

    request_body = JSON.parse(request.body.read)

    user_name = request_body['user_name']
    password = request_body['password']

    found, admin, error_message = USERS_DB.get_user(user_name, password).values_at(:found, :isAdmin, :error_message)

    response_body = { authenticated: found, access_token: '', error_message: error_message }

    if found
      session_token = request.cookies['session_token']

      begin
        decoded_session_token = JWT.decode(session_token, JWT_RSA_PUBLIC_KEY, true,
                                           { algorithm: SESSION_TOKEN_ALGO })[0]
        if decoded_session_token['user_name'] != user_name || decoded_session_token['password'] != password
          create_new_session_token = true
        end
      rescue JWT::VerificationError, JWT::DecodeError
        create_new_session_token = true
      end

      if create_new_session_token
        session_token_payload = { **request_body, admin: admin }
        session_token = JWT.encode(session_token_payload, JWT_RSA_PRIVATE_KEY, SESSION_TOKEN_ALGO)

        response.set_cookie('session_token', { value: session_token, expires: Date.today + 30, httpOnly: true })
      end

      access_token_payload = { user_name: user_name, admin: admin, ttl: Date.today + 7, salt: SecureRandom.hex(12) }
      response_body[:access_token] = JWT.encode(access_token_payload, session_token, ACCESS_TOKEN_ALGO)
    end

    response_body.to_json
  end

  get '/get/:key' do
    content_type :json
    { data: DB_STORE.get(params[:key]) }.to_json
  end

  get '/keys' do
    content_type :json
    { data: DB_STORE.keys }.to_json
  end

  post '/put/:key' do
    content_type :json
    input_data = JSON.parse(request.body.read)

    { data: DB_STORE.put(params[:key], input_data['value']) }.to_json
  end

  delete '/del/:key' do
    content_type :json
    { data: DB_STORE.delete(params[:key]) }.to_json
  end

  delete '/wipe' do
    content_type :json
    { data: DB_STORE.wipe }.to_json
  end
end

puts "HTTP server started on port: #{HTTP_PORT}"
