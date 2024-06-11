# frozen_string_literal: true

require 'socket'
require 'json'
require 'json-schema'

require_relative '../../ruby-kv/serializer'
require_relative '../../ruby-kv/disk_store'

PORT = 2000

server = TCPServer.open(PORT)
puts "Server started at: localhost:#{PORT}"

def parse_json(json_string)
  schema = {
    'type' => 'object',
    'required' => %w[method key],
    'properties' => {
      'method' => { 'type' => 'string' },
      'key' => { 'type' => 'string' },
      'value' => {
        'anyOf' => [
          { 'type' => 'string' },
          { 'type' => 'number' }
        ]
      }
    }
  }

  json_data = JSON.parse(json_string)
  valid_json = JSON::Validator.validate(schema, json_data)

  { error: !valid_json, data: valid_json ? json_data : 'ERR: invalid json data' }
rescue JSON::ParserError, TypeError => e
  { error: true, data: "ERR: invalid input ---- #{e.message}" }
end

loop do
  Thread.start(server.accept) do |client|
    client_address = client.peeraddr[3]
    puts "New connection from: #{client_address}"
    client.puts 'Connected to server'

    db_store = RubyKV::DiskStore.new

    while (line = client.gets)
      line.chomp!
      break if line == 'exit'

      input = parse_json(line)
      input_data = input[:data]

      if input[:error]
        client.puts input_data
      else
        method = input_data['method'].upcase
        key = input_data['key']
        value = input_data['value']

        case method
        when 'PUT'
          puts "Client: #{client_address}, added data to kv_store. K: #{key}, V: #{value}"
          client.puts db_store.put(key, value)
        when 'GET'
          puts "Client: #{client_address}, retrieved #{key} from kv_store."
          client.puts db_store.get(key)
        when 'DEL'
          puts "Client: #{client_address}, deleted #{key} from kv_store."
          client.puts db_store.delete(key)
        when 'KEYS'
          puts "Client: #{client_address}, listed keys from kv_store."
          client.puts db_store.keys
        when 'WIPE'
          puts "Client: #{client_address}, deleted all data from kv_store."
          client.puts db_store.wipe
        else
          client.puts "ERR: invalid method: #{method}"
        end
      end
    end
    client.puts 'Disconnected from server'
    client.close
  end
end
