# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "capistrano-deploy-lock"
  spec.version       = "1.0.3"
  spec.author        = "Maruf Hasan Bulbul"
  spec.email         = "mhb.cse@gmail.com"
  spec.summary       = %q{Deploy lock feature for Capistrano 3.4.x}
  spec.description   = %q{Lock deploy when deployment is running or custom lock to prevent further deployment for Capistrano 3.}
  spec.homepage      = "https://github.com/maruf-freelancer/capistrano-deploy-lock"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency 'capistrano', '>= 3.4'
  spec.add_development_dependency "rake", ">= 10.0"
  spec.required_ruby_version = '>= 1.9.3'
end