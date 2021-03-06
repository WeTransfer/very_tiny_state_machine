# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'very_tiny_state_machine'

Gem::Specification.new do |s|
  s.name = 'very_tiny_state_machine'
  s.version = VeryTinyStateMachine::VERSION

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.require_paths = ['lib']
  s.authors = ['Julik Tarkhanov']
  s.description = "You wouldn't beleive how tiny it is"
  s.email = 'me@julik.nl'
  s.extra_rdoc_files = [
    'LICENSE.txt',
    'README.md'
  ]
  s.files = `git ls-files -z`.split("\x0")
  s.homepage = 'http://github.com/WeTransfer/very_tiny_state_machine'
  s.licenses = ['MIT']
  s.rubygems_version = '2.4.5.1'
  s.summary = 'A minuscule state machine for storing state of interesting objects'

  s.specification_version = 4
  s.add_development_dependency('bundler')
  s.add_development_dependency('rake', '~> 12')
  s.add_development_dependency('rdoc', ['~> 3'])
  s.add_development_dependency('rspec', ['~> 3'])
  s.add_development_dependency('simplecov', ['~> 0.10'])
  s.add_development_dependency('wetransfer_style', '0.6.0') # Lock since we want to be backwards-compat down to Ruby 2.1
  s.add_development_dependency('yard')
end
