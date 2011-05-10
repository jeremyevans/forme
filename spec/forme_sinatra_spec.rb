require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

require 'rubygems'
require 'sinatra/base'
require 'forme/sinatra'
require 'erb'

class FormeSinatraTest < Sinatra::Base
  helpers Forme::Sinatra::ERB
  disable :show_exceptions

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
  <p>FBB</p>
  <% f.tag(:div) do %>
    <%= f.input(:first) %>
    <%= f.input(:last) %>
  <% end %>
<% end %>
END
  end
end

describe "Forme Sinatra ERB integration" do
  specify "#form should add start and end tags and yield Forme::Form instance" do
    FormeSinatraTest.new.call({'rack.input'=>'', 'REQUEST_METHOD'=>'GET', 'PATH_INFO'=>'/'})[2].join.gsub(/\s+/, ' ').should == '<form action="/baz"> <p>FBB</p> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> </form>'
  end

  specify "#form should add start and end tags and yield Forme::Form instance" do
    FormeSinatraTest.new.call({'rack.input'=>'', 'REQUEST_METHOD'=>'GET', 'PATH_INFO'=>'/nest'})[2].join.gsub(/\s+/, ' ').should == '<form action="/baz"> <p>FBB</p> <div> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> </div> </form>'
  end
end
