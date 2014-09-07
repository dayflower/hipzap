# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hipzap'

Gem::Specification.new do |spec|
  spec.name          = "hipzap"
  spec.version       = HipZap::VERSION
  spec.authors       = ["ITO Nobuaki"]
  spec.email         = ["daydream.trippers@gmail.com"]
  spec.summary       = %q{Unified stream viewer for HipChat messages}
  spec.description   = %q{Display talk messages of multiple rooms in HipChat as unified stream}
  spec.homepage      = "http://github.com/dayflower/hipzap"
  spec.license       = "MIT"

  spec.files         = [
    "hipzap.gemspec",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "hipzap.example.conf",
    "lib/hipzap.rb",
    "bin/hipzap",
  ]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "xrc", ">= 0.1.3"
  spec.add_dependency "ansi"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
