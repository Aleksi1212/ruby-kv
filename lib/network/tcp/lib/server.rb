# frozen_string_literal: true
# rubocop:disable all

require_relative '../../../ruby_kv'
require_relative '../../sql/users'
require_relative 'json'

def kv_operations(input_data, client_address)
  kv_store = RubyKV::DiskStore.new

  method = input_data['method'].upcase
  key = input_data['key']
  value = input_data['value']

  case method
  when 'PUT'
    puts "Client #{client_address}, added data to kv_store. K: #{key}, V: #{value}"
    kv_store.put(key, value)
  when 'GET'
    puts "Client #{client_address}, retrieved #{key} from kv_store."
    kv_store.get(key)
  when 'DEL'
    puts "Client #{client_address}, deleted #{key} from kv_store."
    kv_store.delete(key)
  when 'KEYS'
    puts "Client #{client_address}, listed keys from kv_store."
    kv_store.keys
  when 'WIPE'
    puts "Client #{client_address}, deleted all data from kv_store."
    kv_store.wipe
  else
    "ERR: invalid method: #{method}"
  end
end

def handle_client_connection(client)
  puts "New connection from #{client.peeraddr[3]}. #{Time.now}"
  client.puts 'Connected to server'

  users_db = Users.new
  
  authenticated = false
  admin = false

  while (line = client.gets)
    line.chomp!
    break if line.downcase == 'exit'

    if line.downcase == 'hello' || line.downcase == 'hi'
      client.puts 'Hi!'
    else
      kv_input = parse_json(line, Schemas::KV)
      auth_input = parse_json(line, Schemas::AUTH)

      kv_input_error, kv_input_data = kv_input.values_at(:error, :data)
      auth_input_error, auth_input_data = auth_input.values_at(:error, :data)

      client.puts "#{kv_input_data} | #{auth_input_data}" if kv_input_error && auth_input_error

      if kv_input_error && !auth_input_error
        user_name = auth_input_data['user_name']
        password = auth_input_data['password']

        authenticated, admin = users_db.get_user(user_name, password).values_at(:found, :isAdmin)

        client.puts authenticated ?
          "Authenticated as #{admin ? 'Admin' : 'User'}: #{user_name}" :
          "Invalid password for User: #{user_name}"
      end

      if !kv_input_error && auth_input_error
        client.puts kv_operations(kv_input_data, client.peeraddr[3]) if authenticated
        client.puts 'Not authenticated' unless authenticated
      end
    end
  end
  client.puts 'Disconnected from server'
  client.close
  puts "Connection to #{client.peeraddr[3]} closed"
rescue Errno::ECONNRESET
  puts 'Connection was forcibly closed by client'
rescue IOError, OpenSSL::SSL::SSLError
  puts 'Encountered IO error, client likely gone'
end
