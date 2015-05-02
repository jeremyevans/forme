$:.unshift(File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'lib'))

if ENV['COVERAGE']
  require File.join(File.dirname(File.expand_path(__FILE__)), "forme_coverage")
  SimpleCov.forme_coverage
end

require 'forme'
require 'minitest/autorun'
