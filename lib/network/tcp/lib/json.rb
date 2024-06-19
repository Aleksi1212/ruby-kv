# frozen_string_literal: true

require 'json'
require 'json-schema'

module Schemas
  KV = {
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
  }.freeze

  AUTH = {
    'type' => 'object',
    'required' => %w[method user_name password],
    'properties' => {
      'method' => { 'const' => 'AUTH' },
      'user_name' => { 'type' => 'string' },
      'password' => { 'type' => 'string' }
    }
  }.freeze
end

def parse_json(json_string, schema)
  json_data = JSON.parse(json_string)
  valid_json = JSON::Validator.validate(schema, json_data)

  { error: !valid_json, data: valid_json ? json_data : 'ERR: invalid json data' }
rescue JSON::ParserError, TypeError => e
  { error: true, data: "ERR: invalid input ---- #{e.message}" }
end
