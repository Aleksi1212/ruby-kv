# frozen_string_literal: true

require_relative '../lib/ruby-kv/serializer'
require_relative '../lib/ruby-kv/disk_store'

$db_store = RubyKV::DiskStore.new

$tests = {
  PUT: {
    test1: %w[test1 data1],
    test2: %w[test2 data2],
    test3: %w[test3 data3],
    test4: %w[test4 data4],
    test5: %w[test5 data5]
  },
  GET_AND_DEL: %w[
    test1
    test2
    test3
    test4
    test5
  ]
}

def put_test
  $tests[:PUT].each do |key, value|
    put_test_val = $db_store.put(value[0], value[1])
    if put_test_val == 'OK'
      puts "PUT #{key} OK\n"
    else
      puts "PUT #{key} FAILED: #{put_test_val}\n"
    end
  end
end

def get_test
  $tests[:GET_AND_DEL].each do |test|
    get_test_val = $db_store.get(test)
    if get_test_val.include?('ERROR')
      puts "GET #{test} FAILED: #{get_test_val}\n"
    else
      puts "GET #{test} OK. Data value: #{get_test_val}\n"
    end
  end
end

def del_test
  $tests[:GET_AND_DEL].each do |test|
    del_test_val = $db_store.delete(test)
    if del_test_val == 'OK'
      puts "DEL #{test} OK\n"
    else
      puts "DEL #{test} FAILED: #{del_test_val}\n"
    end
  end
end

puts "\n-----------------"
puts "Starting PUT test\n"
puts "-----------------\n\n"

put_test

puts "\n-----------------"
puts "Starting GET test\n"
puts "-----------------\n\n"

get_test

puts "\n-----------------"
puts "Starting DEL test\n"
puts "-----------------\n\n"

del_test

puts "\n-----------------"
puts "Starting PUT test 2\n"
puts "-----------------\n\n"

put_test

puts "\n-----------------"
puts "Starting DEL test 2\n"
puts "-----------------\n\n"

del_test

puts "\n\nAll tests run"
