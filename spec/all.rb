$: << 'lib'
Dir.new(File.dirname(__FILE__)).each{|f| require_relative f if f.end_with?('_spec.rb')}
