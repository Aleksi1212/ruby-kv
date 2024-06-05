# frozen_string_literal: true

module RubyKV
  class DiskStore
    include Serializer

    def initialize(db_file = 'ruby_kv.db')
      @db_fh = File.open(db_file, 'a+b')
      @write_pos = 0
      @key_dir = {}
    end

    def get(key)
      key_struct = @key_dir[key]
      return '' if key_struct.nil?

      @db_fh.seek(key_struct[:write_pos])
      _, _, value = deserialize(@db_fh.read(key_struct[:log_size]))

      value
    end

    def put(key, value)
      log_size, data = serialize(epoch: Time.now.to_i, key: key, value: value)

      @key_dir[key] = key_struct(@write_pos, log_size, key)
      persist(data)
      incr_write_pos(log_size)

      nil
    end

    def flush
      @db_fh.flush
    end

    def persist(data)
      @db_fh.write(data)
      @db_fh.flush
    end

    def incr_write_pos(pos)
        @write_pos += pos
    end

    def key_struct(write_pos, log_size, key)
      { write_pos: write_pos, log_size: log_size, key: key }
    end
  end
end
