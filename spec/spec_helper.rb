$:.unshift(File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'lib'))

if ENV['COVERAGE']
  require File.join(File.dirname(File.expand_path(__FILE__)), "forme_coverage")
  SimpleCov.forme_coverage
end

require 'forme'

if defined?(RSpec)
  require 'rspec/version'
  if RSpec::Version::STRING >= '2.11.0'
    RSpec.configure do |config|
      config.expect_with :rspec do |c|
        c.syntax = :should
      end
      config.mock_with :rspec do |c|
        c.syntax = :should
      end
    end
  end
end
