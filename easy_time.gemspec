require_relative 'lib/easy_time/version'

Gem::Specification.new do |spec|
  spec.name          = "easy_time"
  spec.version       = EasyTime::VERSION
  spec.authors       = ["Alan Stebbens"]
  spec.email         = ["aks@stebbens.org"]

  spec.summary       = %q{Easy auto-conversion of most date and time values with tolerant-comparisons}
  spec.description   = 
    <<~DESC

      A class that makes it easy to work with most known time and date values,
      and perform tolerant comparisons.  The default tolerance is 1 minute,
      which allows for timestamps from differing systems to be compared and if
      the difference of their values is less than a minute would be considered
      equal.  The tolerance can be configured, even set to zero.

    DESC
  spec.homepage      = 'https://github.com/aks/easy_time'
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aks/easy_time"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "fuubar", ">= 2.5.0"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-yard"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec_junit"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "rubocop", ">= 0.82.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "terminal-notifier-guard" if /Darwin/.match?(`uname -a`.strip)
  spec.add_development_dependency "yard", ">= 0.9.24"

  spec.add_dependency "activesupport"
end
