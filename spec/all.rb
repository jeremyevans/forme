require 'rubygems'
$: << 'lib'
Dir['./spec/*_spec.rb'].each{|f| require f}
