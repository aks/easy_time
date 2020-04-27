require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'yard'

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "run tests with code coverage"
  task :coverage do
    sh "CODE_COVERAGE=1 bundle exec rake spec"
  end
end

YARD::Rake::YardocTask.new do |t|
  t.options += ['--title', "EasyTime #{EasyTime::VERSION} Documentation"]
  t.stats_options = ['--list-undoc']
end

task :default => :spec
