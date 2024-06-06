# frozen_string_literal: true

require_relative 'ruby-kv/serializer'
require_relative 'ruby-kv/disk_store'

args = ARGV

if args.empty?
  puts 'No arguments provided'
else
  db_store = RubyKV::DiskStore.new

  if args[0] == 'put'
    db_store.put(args[1], args[2])
    puts 'Data added succesfully'
  elsif args[0] == 'get'
    puts db_store.get(args[1])
  end
end
