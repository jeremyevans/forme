require 'coverage'
require 'simplecov'

def SimpleCov.forme_coverage
  start do
    coverage :line
    coverage :branch
    cover "lib/**/*.rb"
    group('Missing'){|src| src.covered_percent < 100}
  end
end

ENV.delete('COVERAGE')
