# frozen_string_literal: true

require_relative '../lib/ruby-kv/serializer'
require_relative '../lib/ruby-kv/disk_store'

args = ARGV

if args.empty?
  puts 'No arguments provided'
else
  db_store = RubyKV::DiskStore.new

  case args[0]
  when 'put'
    kv = args[1].split(':')
    puts db_store.put(kv[0], kv[1])
  when 'get'
    puts db_store.get(args[1])
  when 'del'
    puts db_store.delete(args[1])
  when 'keys'
    puts db_store.keys
  when 'wipe'
    puts db_store.wipe
  end
end
