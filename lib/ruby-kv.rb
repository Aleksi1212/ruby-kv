require_relative 'ruby-kv/serializer'
require_relative 'ruby-kv/disk_store'

db_store = RubyKV::DiskStore.new()

db_store.put("Anime", "sex")
puts db_store.get("Anime")