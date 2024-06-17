# frozen_string_literal: true

require_relative '../../../ruby_kv'
require_relative 'json'


def db_operations(input_data, client_address)
  db_store = RubyKV::DiskStore.new

  method = input_data['method'].upcase
  key = input_data['key']
  value = input_data['value']

  case method
  when 'PUT'
    puts "Client #{client_address}, added data to kv_store. K: #{key}, V: #{value}"
    db_store.put(key, value)
  when 'GET'
    puts "Client #{client_address}, retrieved #{key} from kv_store."
    db_store.get(key)
  when 'DEL'
    puts "Client #{client_address}, deleted #{key} from kv_store."
    db_store.delete(key)
  when 'KEYS'
    puts "Client #{client_address}, listed keys from kv_store."
    db_store.keys
  when 'WIPE'
    puts "Client #{client_address}, deleted all data from kv_store."
    db_store.wipe
  else
    "ERR: invalid method: #{method}"
  end
end

def handle_client_connection(client)
  client_address = client.peeraddr[3]
  puts "New connection from #{client_address}. #{Time.now}"
  client.puts 'Connected to server'

  while (line = client.gets)
    line.chomp!
    break if line.downcase == 'exit'

    if line.downcase == 'hello' || line.downcase == 'hi'
      client.puts 'Hi!'
    else
      input = parse_json(line)
      input_data = input[:data]

      client.puts input_data if input[:error]
      client.puts db_operations(input_data, client_address) unless input[:error]
    end
  end
  client.puts 'Disconnected from server'
  client.close
  puts "Connection to #{client_address} closed"
rescue Errno::ECONNRESET
  puts 'Connection was forcibly closed by client'
rescue IOError, OpenSSL::SSL::SSLError
  puts 'Encountered IO error, client likely gone'
end
