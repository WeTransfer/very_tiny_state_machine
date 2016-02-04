# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: very_tiny_state_machine 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "very_tiny_state_machine"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Julik Tarkhanov"]
  s.date = "2016-02-04"
  s.description = "You wouldn't beleive how tiny it is"
  s.email = "me@julik.nl"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".travis.yml",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "lib/very_tiny_state_machine.rb",
    "spec/spec_helper.rb",
    "spec/very_tiny_state_machine_spec.rb",
    "very_tiny_state_machine.gemspec"
  ]
  s.homepage = "http://github.com/WeTransfer/very_tiny_state_machine"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "A minuscule state machine for storing state of interesting objects"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 3.2.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.10"])
    else
      s.add_dependency(%q<rspec>, ["~> 3.2.0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_dependency(%q<simplecov>, ["~> 0.10"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 3.2.0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
    s.add_dependency(%q<simplecov>, ["~> 0.10"])
  end
end

