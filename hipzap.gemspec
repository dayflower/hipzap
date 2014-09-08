# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hipzap/version'

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
    "lib/hipzap/version.rb",
    "lib/hipzap/config.rb",
    "lib/hipzap/engine.rb",
    "lib/hipzap/renderer/standard.rb",
    "lib/hipzap/renderer/colorful.rb",
    "bin/hipzap",
    "examples/osx-keychain/Gemfile",
    "examples/osx-keychain/hipzap_with_chain.rb",
    "examples/osx-keychain/register_to_chain.rb",
  ]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "xrc", ">= 0.1.3"
  spec.add_dependency "ansi"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
