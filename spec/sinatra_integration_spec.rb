require_relative 'spec_helper'
require_relative 'sequel_helper'
require_relative 'erb_helper'

begin
require 'sinatra/base'
require 'rack/csrf'
rescue LoadError
  warn "unable to load sinatra or rack/csrf, skipping sinatra spec"
else
begin
  require 'tilt/erubis'
rescue LoadError
  require 'tilt/erb'
  begin
    require 'erubis'
  rescue LoadError
    require 'erb'
  end
end
require_relative '../lib/forme/erb'
class FormeSinatraTest < Sinatra::Base
  helpers(Forme::ERB::Helper)
  disable :show_exceptions
  enable :raise_errors
  enable :sessions
  use Rack::Csrf

  def self.get(path, &block)
    super("/#{path}", &block)
  end

  instance_exec(self, &ERB_BLOCK)

  get 'no-session' do
    session = env.delete('rack.session')
    body = erb <<END
<% form(:method=>'POST') do %>
<% end %>
END
    env['rack.session'] = session
    body
  end

  get 'no-out_buf' do
    erb(<<END, :outvar=>'@_foo')
<% form(:method=>'POST') do |f| %>
  <%= f.input(:text) %>
<% end %>
END
  end
end

describe "Forme Sinatra ERB integration" do
  def sin_get(path)
    s = String.new
    FormeSinatraTest.new.call(@rack.merge('PATH_INFO'=>path))[2].each{|str| s << str}
    s.gsub(/\s+/, ' ').strip
  end

  include FormeErbSpecs

  it "should handle missing rack.session when using Rack::Csrf" do
    sin_get('/no-session').must_equal '<form method="POST"></form>'
  end

  it "should handle non-standard outvar, but without emitting into template" do
    sin_get('/no-out_buf').must_equal '<input type="text"/>'
  end
end
end
