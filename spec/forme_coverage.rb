require 'coverage'
require 'simplecov'

def SimpleCov.forme_coverage(opts = {})
  start do
    add_filter "/spec/"
    add_group('Missing'){|src| src.covered_percent < 100}
    add_group('Covered'){|src| src.covered_percent == 100}
    yield self if block_given?
  end
end

ENV.delete('COVERAGE')
