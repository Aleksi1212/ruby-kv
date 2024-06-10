# frozen_string_literal: true

task default: :run

task :run, [:arg1, :arg2] do |t, args|
  ruby "test/manual_test.rb #{args[:arg1]} #{args[:arg2]}"
end

task :test do
  ruby 'test/test.rb'
end
