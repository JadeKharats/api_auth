require 'rake/testtask'

task :default => :hello

desc "print 'Hello World'"
task :hello do
  puts 'HelloWorld'
end

Rake::TestTask.new do |t|
  t.pattern = "spec/*_spec.rb"
end
