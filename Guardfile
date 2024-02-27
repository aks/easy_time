# frozen_string_literal: true

# Guardfile for easy_time gem

begin
  require 'terminal-notifier-guard'
  notification :terminal_notifier, app_name: 'easy_time'
rescue LoadError
  warn "Failed to load notifier"
end

guard :rspec,
      all_on_start:   false,
      all_after_pass: false,
      failed_mode:    :focus,
      cmd:            "CODE_COVERAGE=1 bundle exec rspec" do
  directories(%w[lib spec])
    .select { |d| Dir.exist?(d) ? d : UI.warning("Directory #{d} does not exist") }

  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)
end

guard 'yard' do
  watch(%r{lib/.+\.rb})
  watch('README.md')
end
