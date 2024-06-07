# frozen_string_literal: true

require_relative 'ruby-kv/serializer'
require_relative 'ruby-kv/disk_store'

args = ARGV

if args.empty?
  puts 'No arguments provided'
else
  db_store = RubyKV::DiskStore.new

  case args[0]
  when 'put'
    puts db_store.put(args[1], args[2])
  when 'get'
    puts db_store.get(args[1])
  when 'del'
    puts db_store.delete(args[1])
  when 'keys'
    puts db_store.keys
  end
end
