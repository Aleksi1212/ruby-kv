require 'rubocop/rake_task'

task default %w[lint test]

RuboCop::RakeTask.new(:lint) do |task|
    task.pattersns = ['lib/**/*.rb']
    task.fail_on_error = false
end

task :run do
    ruby 'lib/main.rb'
end