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

    def keys
      @key_dir.keys
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
      e.message
    end

    def delete(key)
      key_struct = @key_dir[key]
      return if key_struct.nil?

      @db_fh.seek(0)
      db_data = @db_fh.read

      db_data.slice!(key_struct[:write_pos]..key_struct[:write_pos] + key_struct[:log_size] - 1)

      File.open(@db_file, 'w') do |file|
        file.write(db_data)
        file.flush
      end

      @key_dir = recalculate_write_positions(key)

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

    def recalculate_write_positions(key)
      modified_arr = []
      modified_hash = {}

      @key_dir.each do |dir_key, dir_val|
        modified_arr.push(dir_val) if dir_key != key
      end

      (0..modified_arr.length - 1).each do |index|
        if index.zero?
          modified_arr[index][:write_pos] = 0
        else
          modified_arr[index][:write_pos] = modified_arr[index - 1][:write_pos] + modified_arr[index - 1][:log_size]
        end

        @write_pos = modified_arr[index][:write_pos]
        modified_hash[modified_arr[index][:key]] = modified_arr[index]
      end

      modified_hash
    end
  end
end
