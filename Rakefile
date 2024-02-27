# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop-rake"
require "rubocop/rake_task"
require 'yard'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

namespace :spec do
  desc "run tests with code coverage"
  task :coverage do
    sh "CODE_COVERAGE=1 bundle exec rake spec"
  end
end

task default: %i[spec rubocop]
task install: %i[build spec clean]
task release: %i[build spec install]

namespace :bundle do
  desc 'add linux platform to Gemfile.lock'
  task :add_linux do
    sh "grep -s 'x86_64-linux' Gemfile.lock >/dev/null || bundle lock --add-platform x86_64-linux"
  end
end

YARD::Rake::YardocTask.new do |t|
  t.options += ['--title', "EasyTime #{EasyTime::VERSION} Documentation"]
  t.stats_options = ['--list-undoc']
end
