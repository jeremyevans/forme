require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'erb_helper.rb')

require 'rubygems'
begin
require 'roda'
require(ENV['ERUBIS'] ? 'erubis' : 'erb')
require 'rack/csrf'
rescue LoadError
  warn "unable to load roda or rack/csrf, skipping roda spec"
else
class FormeRodaTest < Roda
  plugin :forme
  use Rack::Session::Cookie, :secret => "__a_very_long_string__"
  use Rack::Csrf

  def erb(s, opts={})
    render(opts.merge(:inline=>s))
  end

  route do |r|
    instance_exec(r, &ERB_BLOCK)
  end
end

describe "Forme Roda ERB integration" do
  def sin_get(path)
    s = ''
    FormeRodaTest.app.call(@rack.merge('PATH_INFO'=>path))[2].each{|str| s << str}
    s.gsub(/\s+/, ' ').strip
  end

  it_should_behave_like "erb integration"
end
end
