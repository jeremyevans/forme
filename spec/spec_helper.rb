$:.unshift(File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'lib'))

if ENV['WARNING']
  require 'warning'
  Warning.ignore([:missing_ivar, :not_reached])
end

if ENV['COVERAGE']
  require File.join(File.dirname(File.expand_path(__FILE__)), "forme_coverage")
  SimpleCov.forme_coverage
end

require 'forme'

require 'rubygems'
ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/autorun'
