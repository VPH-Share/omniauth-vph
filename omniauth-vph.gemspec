# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth-vph/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-vph"
  spec.version       = Omniauth::Vph::VERSION
  spec.authors       = ["Marek Kasztelnik"]
  spec.email         = ["mkasztelnik@gmail.com"]
  spec.description   = %q{A VPH-Share Master Interface strategy for OmniAuth.}
  spec.summary       = %q{A VPH-Share Master Interface strategy for OmniAuth.}
  spec.homepage      = "http://dice.cyfronet.pl"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency     'omniauth', '~> 1.0'
  spec.add_runtime_dependency     'multi_json'
  spec.add_runtime_dependency     'faraday'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rack-test'
end
