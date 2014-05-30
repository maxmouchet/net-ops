# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net/ops/version'

Gem::Specification.new do |spec|
  spec.name          = 'net-ops'
  spec.version       = Net::Ops::VERSION
  spec.authors       = ['Maxime Mouchet']
  spec.email         = ['mouchet.max@gmail.com']
  spec.description   = %q{Framework to automate daily operations on network devices.}
  spec.summary       = %q{Net::Ops}
  spec.homepage      = 'http://github.com/maxmouchet/net-ops'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'thread', '~> 0.1'
  spec.add_runtime_dependency 'net-ssh-telnet', '~> 0.0.2'
  spec.add_runtime_dependency 'term-ansicolor', '~> 1.3'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
