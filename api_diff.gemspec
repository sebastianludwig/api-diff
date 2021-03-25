require_relative 'lib/api_diff/version'

Gem::Specification.new do |spec|
  spec.name          = "api_diff"
  spec.version       = ApiDiff::VERSION
  spec.authors       = ["Sebastian Ludwig"]
  spec.email         = ["sebastian@lurado.de"]

  spec.summary       = %q{Bring APIs into an easily diff-able format}
  # spec.description TODO
  spec.homepage      = "https://github.com/sebastianludwig/api-diff"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sebastianludwig/api_diff"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "byebug", "~> 11"

  spec.files        = %w( Gemfile README.md LICENSE )
  spec.files       += Dir.glob("lib/**/*")
  spec.files       += Dir.glob("exe/*")
  spec.test_files   = Dir.glob("test/*.rb")

  spec.bindir        = "exe"
  spec.executables   = %w( api_diff )
  spec.require_paths = ["lib"]
end
