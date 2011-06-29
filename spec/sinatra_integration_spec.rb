require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

require 'rubygems'
require 'sinatra/base'
require 'forme/sinatra'
require 'erb'

class FormeSinatraTest < Sinatra::Base
  helpers Forme::Sinatra::ERB
  disable :show_exceptions
  enable :raise_errors

  get '/' do
    erb <<END
<% form([:foo, :bar], :action=>'/baz') do |f| %>
  <p>FBB</p>
  <%= f.input(:first) %>
  <%= f.input(:last) %>
<% end %>
END
  end

  get '/nest' do
    erb <<END
<% form([:foo, :bar], :action=>'/baz') do |f| %>
  <%= f.tag(:p, {}, 'FBB') %>
  <% f.tag(:div) do %>
    <%= f.input(:first) %>
    <%= f.input(:last) %>
  <% end %>
<% end %>
END
  end

  get '/hash' do
    erb "<% form({:action=>'/baz'}, :obj=>[:foo]) do |f| %> <%= f.input(:first) %> <% end %>"
  end

  get '/legend' do
    erb <<END
<% form([:foo, :bar], :action=>'/baz') do |f| %>
  <p>FBB</p>
  <%= f.inputs([:first, :last], :legend=>'Foo') %>
  <p>FBB2</p>
<% end %>
END
  end

  get '/combined' do
    erb <<END
<% form([:foo, :bar], {:action=>'/baz'}, :inputs=>[:first], :button=>'xyz', :legend=>'123') do |f| %>
  <p>FBB</p>
  <%= f.input(:last) %>
<% end %>
END
  end

  get '/noblock' do
    erb "<%= form([:foo, :bar], {:action=>'/baz'}, :inputs=>[:first], :button=>'xyz', :legend=>'123') %>"
  end
end

describe "Forme Sinatra ERB integration" do
  def sin_get(path)
    FormeSinatraTest.new.call(@rack.merge('PATH_INFO'=>path))[2].join.gsub(/\s+/, ' ').strip
  end
  before do
    o = Object.new
    def o.puts(*) end
    @rack = {'rack.input'=>'', 'REQUEST_METHOD'=>'GET', 'rack.errors'=>o}
  end
  specify "#form should add start and end tags and yield Forme::Form instance" do
    sin_get('/').should == '<form action="/baz"> <p>FBB</p> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> </form>'
  end

  specify "#form should add start and end tags and yield Forme::Form instance" do
    sin_get('/nest').should == '<form action="/baz"> <p>FBB</p> <div> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> </div> </form>'
  end

  specify "#form should accept two hashes instead of requiring obj as first argument" do
    sin_get('/hash').should == '<form action="/baz"> <input id="first" name="first" type="text" value="foo"/> </form>'
  end

  specify "#form should deal with emitted code" do
    sin_get('/legend').should == '<form action="/baz"> <p>FBB</p> <fieldset class="inputs"><legend>Foo</legend><input id="first" name="first" type="text" value="foo"/><input id="last" name="last" type="text" value="bar"/></fieldset> <p>FBB2</p> </form>'
  end

  specify "#form should work with :inputs, :button, and :legend options" do
    sin_get('/combined').should == '<form action="/baz"><fieldset class="inputs"><legend>123</legend><input id="first" name="first" type="text" value="foo"/></fieldset> <p>FBB</p> <input id="last" name="last" type="text" value="bar"/> <input type="submit" value="xyz"/></form>'
  end

  specify "#form should work without a block" do
    sin_get('/noblock').should == '<form action="/baz"><fieldset class="inputs"><legend>123</legend><input id="first" name="first" type="text" value="foo"/></fieldset><input type="submit" value="xyz"/></form>'
  end
end
