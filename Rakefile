# frozen_string_literal: true

task default: :run

task :run, [:arg1, :arg2] do |_t, args|
  ruby "spec/other/manual_test.rb #{args[:arg1]} #{args[:arg2]}"
end
