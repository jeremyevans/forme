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
require_relative '../lib/forme/sinatra'
class FormeSinatraTest < Sinatra::Base
  helpers(Forme::Sinatra::ERB)
  disable :show_exceptions
  enable :raise_errors
  enable :sessions
  use Rack::Csrf

  def self.get(path, &block)
    super("/#{path}", &block)
  end

  instance_exec(self, &ERB_BLOCK)
end

describe "Forme Sinatra ERB integration" do
  def sin_get(path)
    s = String.new
    FormeSinatraTest.new.call(@rack.merge('PATH_INFO'=>path))[2].each{|str| s << str}
    s.gsub(/\s+/, ' ').strip
  end

  include FormeErbSpecs
end
end
