# frozen_string_literal: true

module RubyKV
  class DiskStore
    include Serializer

    def initialize(db_file = 'ruby_kv.db')
      @db_file = db_file
      @db_fh = File.open(db_file, 'a+b')
      @write_pos = 0
      @key_dir = {}

      init_key_dir
    end

    def wipe
      @key_dir = {}
      @write_pos = 0
      File.open(@db_file, 'w')
      'OK'
    rescue StandardError => e
      "ERROR: #{e.message}"
    end

    def keys
      @key_dir.keys
    rescue StandardError => e
      "ERROR: #{e.message}"
    end

    def get(key)
      key_struct = @key_dir[key]
      return '' if key_struct.nil?

      @db_fh.seek(key_struct[:write_pos])
      _, _, value = deserialize(@db_fh.read(key_struct[:log_size]))
      value
    rescue StandardError => e
      "ERROR: #{e.message}"
    end

    def put(key, value)
      log_size, data = serialize(epoch: Time.now.to_i, key: key, value: value)

      @key_dir[key] = key_struct(@write_pos, log_size, key)
      persist(data)
      incr_write_pos(log_size)
      'OK'
    rescue StandardError => e
      "ERROR: #{e.message}"
    end

    def delete(key)
      key_struct = @key_dir[key]
      return if key_struct.nil?

      updated_key_dir = {}

      @key_dir.each_key do |dir_key|
        updated_key_dir[dir_key] = get(dir_key) if dir_key != key
      end

      error = wipe
      if error == 'OK'
        updated_key_dir.each do |dir_key, dir_value|
          put(dir_key, dir_value)
        end
      else
        error
      end

      'OK'
    rescue StandardError => e
      "ERROR: #{e.message}"
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

    def init_key_dir
      while (crc_and_header_bytes = @db_fh.read(crc32_header_offset))
        header_bytes = crc_and_header_bytes[crc32_offset..]
        _epoch, keysz, valuesz, key_type, value_type = deserialize_header(header_bytes)

        key_bytes = @db_fh.read(keysz)
        value_bytes = @db_fh.read(valuesz)

        key = unpack(key_bytes, key_type)
        _value = unpack(value_bytes, value_type)

        crc = crc_and_header_bytes[..crc32_offset - 1]
        raise StandardError, 'file corrupted' unless crc32_valid?(
          deserialize_crc32(crc),
          header_bytes + key_bytes + value_bytes
        )

        log_size = crc32_header_offset + keysz + valuesz
        @key_dir[key] = key_struct(@write_pos, log_size, key)
        incr_write_pos(log_size)
      end
    end
  end
end
