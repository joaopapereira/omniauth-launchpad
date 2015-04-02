# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/launchpad/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-launchpad"
  spec.version       = Omniauth::Launchpad::VERSION
  spec.authors       = ["João Pereira"]
  spec.email         = ["joaopapereira@gmail.com"]
  spec.summary       = %q{Launchpad login for OmniAuth}
  spec.description   = %q{This gem will allow users to login with the Launchpad account}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec'
  
  spec.add_runtime_dependency 'omniauth', '>= 1.1.1'
  spec.add_runtime_dependency 'omniauth-oauth', '>= 1.0.1'
  spec.add_runtime_dependency 'multi_json', '~> 1.3'
end
