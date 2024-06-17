# frozen_string_literal: true

require 'json'
require 'json-schema'

SCHEMA = {
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

def parse_json(json_string)
  json_data = JSON.parse(json_string)
  valid_json = JSON::Validator.validate(SCHEMA, json_data)

  { error: !valid_json, data: valid_json ? json_data : 'ERR: invalid json data' }
rescue JSON::ParserError, TypeError => e
  { error: true, data: "ERR: invalid input ---- #{e.message}" }
end
