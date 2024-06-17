# frozen_string_literal: true

require 'sinatra'
require 'sinatra/namespace'

require_relative '../../ruby_kv'

set :port, 8080

DB_STORE = RubyKV::DiskStore.new

namespace '/ruby_kv/api/v1' do
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
