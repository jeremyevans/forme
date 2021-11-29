$:.unshift(File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'lib'))

if ENV['WARNING']
  require 'warning'
  Warning.ignore([:missing_ivar, :not_reached, :method_redefined])
end

if ENV['COVERAGE']
  require_relative 'forme_coverage'
  SimpleCov.forme_coverage
end

require_relative '../lib/forme'

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/global_expectations/autorun'

module Minitest::Spec::DSL
  def silence_warnings(name, &block)
    it(name) do
      silence_warnings do
        instance_exec(&block)
      end
    end
  end
end

class Minitest::Spec
  def silence_warnings
    verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = verbose
  end
end
