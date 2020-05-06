# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'simplecov'
SimpleCov.start

require 'very_tiny_state_machine'

RSpec.configure { |config| config.order = 'random' }
