# frozen_string_literal: true

require_relative 'lib/easy_time/version'

Gem::Specification.new do |spec|
  spec.name          = "easy_time"
  spec.version       = EasyTime::VERSION
  spec.authors       = ["Alan Stebbens"]
  spec.email         = ["aks@stebbens.org"]

  spec.summary       = "Easy auto-conversion of most date and time values with tolerant-comparisons"
  spec.description   =
    <<~'DESC'

      A class that wraps the Time class and makes it easy to work with most
      known time values, including various time strings, automatically
      converting them to Time values, and perform tolerant comparisons.
      Several time classes, and the String class, are extended with the
      ".easy_time" method to perform an auto-conversion.  A tolerant comparison
      allows for times from differing systems to be compared, even when the
      systems are out of sync, using the relationship operators and methods
      like "newer?", "older?", "same?" and "between?".  A tolerant comparison
      for equality is where the difference of two values is less than the
      tolerance value (1 minute by default).  The tolerance can be configured,
      even set to zero.  Finally, all of the Time class and instance methods
      are available on the EasyTime class and instances.

    DESC
  spec.homepage      = 'https://github.com/aks/easy_time'
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  # spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/aks"
  spec.metadata["github_repo"]       = "ssh://github.com/aks/easy_time"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aks/easy_time"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "activesupport", ">= 6.1.4"
  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "fuubar", ">= 2.5.0"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-yard"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec_junit"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rubocop", ">= 0.82.0"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "terminal-notifier-guard" if /Darwin/.match?(`uname -a`.strip)
  spec.add_development_dependency "yard", ">= 0.9.24"

  spec.add_dependency "activesupport"
end
