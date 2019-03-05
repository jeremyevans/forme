require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'erb_helper.rb')

require 'rubygems'
begin
  require 'roda'
  require 'tilt'
rescue LoadError
  warn "unable to load roda or tilt, skipping roda specs"
else
begin
  require 'tilt/erubi'
rescue LoadError
  begin
    require 'tilt/erubis'
  rescue LoadError
    require 'tilt/erb'
  end
end

class FormeRodaTest < Roda
  opts[:check_dynamic_arity] = opts[:check_arity] = :warn
  
  if defined?(Roda::RodaVersionNumber) && Roda::RodaVersionNumber >= 30100
    require 'roda/session_middleware'
    opts[:sessions_convert_symbols] = true
    use RodaSessionMiddleware, :secret=>SecureRandom.random_bytes(64), :key=>'rack.session'
  else
    use Rack::Session::Cookie, :secret => "__a_very_long_string__"
  end

  def erb(s, opts={})
    render(opts.merge(:inline=>s))
  end

  route do |r|
    r.get 'use_request_specific_token', :use do |use|
      render :inline=>"[#{Base64.strict_encode64(send(:csrf_secret))}]<%= form({:method=>:post}, {:use_request_specific_token=>#{use == '1'}}) %>"
    end
    r.get 'hidden_tags' do |use|
      render :inline=>"<%= form({:method=>:post}, {:hidden_tags=>[{:foo=>'bar'}]}) %>"
    end
    r.get 'csrf', :use do |use|
      render :inline=>"<%= form({:method=>:post}, {:csrf=>#{use == '1'}}) %>"
    end
    instance_exec(r, &ERB_BLOCK)
  end
end

begin
  require 'rack/csrf'
rescue LoadError
  warn "unable to load rack/csrf, skipping roda csrf plugin spec"
else
describe "Forme Roda ERB integration with roda forme and csrf plugins" do
  app = FormeRodaCSRFTest = Class.new(FormeRodaTest)
  app.plugin :csrf
  app.plugin :forme
  
  def sin_get(path)
    s = String.new
    FormeRodaCSRFTest.app.call(@rack.merge('PATH_INFO'=>path))[2].each{|str| s << str}
    s.gsub(/\s+/, ' ').strip
  end

  include FormeErbSpecs
end
end

begin
  require 'roda/plugins/route_csrf'
rescue LoadError
  warn "unable to load roda/plugins/route_csrf, skipping forme_route_csrf plugin spec"
else
[{}, {:require_request_specific_tokens=>false}].each do |plugin_opts|
  describe "Forme Roda ERB integration with roda forme_route_csrf and route_csrf plugin with #{plugin_opts}" do
    app = Class.new(FormeRodaTest)
    app.plugin :forme_route_csrf
    app.plugin :route_csrf, plugin_opts

    define_method(:sin_get) do |path|
      s = String.new
      app.call(@rack.merge('PATH_INFO'=>path))[2].each{|str| s << str}
      s.gsub(/\s+/, ' ').strip
    end

    include FormeErbSpecs

    it "should handle the :hidden_tags option" do
      output = sin_get('/use_request_specific_token/1')
      output =~ /\[([^\]]+)\].*?value=\"([^\"]+)\"/
      secret = $1
      token = $2
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/1', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal true
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/2', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal false
    end

    it "should handle the :use_request_specific_token => true option" do
      output = sin_get('/use_request_specific_token/1')
      output =~ /\[([^\]]+)\].*?value=\"([^\"]+)\"/
      secret = $1
      token = $2
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/1', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal true
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/2', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal false
    end

    it "should handle the :use_request_specific_token => false option" do
      output = sin_get('/use_request_specific_token/0')
      output =~ /\[([^\]]+)\].*?value=\"([^\"]+)\"/
      secret = $1
      token = $2
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/0', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal(plugin_opts.empty? ? false : true)
    end

    it "should handle the :hidden_tags option" do
      sin_get('/hidden_tags').must_include 'name="foo" type="hidden" value="bar"'
    end

    it "should handle the :csrf option" do
      sin_get('/csrf/1').must_include '<input name="_csrf" type="hidden" value="'
      sin_get('/csrf/0').wont_include '<input name="_csrf" type="hidden" value="'
    end
  end
end
end
end
