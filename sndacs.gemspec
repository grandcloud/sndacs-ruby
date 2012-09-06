# -*- encoding: utf-8 -*-

# Load version requiring the canonical "sndacs/version", otherwise Ruby will think
# is a different file and complaint about a double declaration of Sndacs::VERSION.
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "sndacs/version"

Gem::Specification.new do |s|
  s.name        = "sndacs"
  s.version     = Sndacs::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["LI Daobing"]
  s.email       = ["lidaobing@snda.com"]
  s.homepage    = "https://github.com/grandcloud/sndacs-ruby"
  s.summary     = "Library for accessing SNDA Cloud Storage buckets and objects"
  s.description = "sndacs library provides access to SNDA Cloud Storage."

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "proxies", "~> 0.2.0"
  s.add_dependency 'mime-types'
  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", "~> 2.0"
  s.add_development_dependency "mocha"
  #s.add_development_dependency "test-unit", ">= 2.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = "lib"
end
