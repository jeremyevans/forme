require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')

require 'rubygems'
begin
require 'action_controller/railtie'
rescue LoadError
  warn "unable to load rails, skipping rails spec"
else
require 'forme/rails'

class FormeRails < Rails::Application
  config.secret_token = routes.append { get ':action' , :controller=>'forme' }.inspect
  config.active_support.deprecation = :stderr
  config.middleware.delete(ActionDispatch::ShowExceptions)
  config.middleware.delete("Rack::Lock")
  config.secret_key_base = 'foo'
  config.eager_load = true
  initialize!
end

class FormeController < ActionController::Base
  helper Forme::Rails::ERB

  def index
    render :inline => <<END
<%= forme([:foo, :bar], :action=>'/baz') do |f| %>
  <p>FBB</p>
  <%= f.input(:first) %>
  <%= f.input(:last) %>
  <%= f.button('Save') %>
<% end %>
END
  end

  def inputs_block
    render :inline => <<END
<%= forme([:foo, :bar], :action=>'/baz') do |f| %>
  <%= f.inputs(:legend=>'FBB') do %>
    <%= f.input(:last) %>
  <% end %>
<% end %>
END
  end

  def inputs_block_wrapper
    render :inline => <<END
<%= forme([:foo, :bar], {:action=>'/baz'}, :inputs_wrapper=>:fieldset_ol) do |f| %>
  <%= f.inputs(:legend=>'FBB') do %>
    <%= f.input(:last) %>
  <% end %>
<% end %>
END
  end

  def nest
    render :inline => <<END
<%= forme([:foo, :bar], :action=>'/baz') do |f| %>
  <%= f.tag(:p, {}, 'FBB') %>
  <%= f.tag(:div) do %>
    <%= f.input(:first) %>
    <%= f.input(:last) %>
  <% end %>

<% end %>
END
  end

  def nest_sep
    @nest = <<END
  n1
  <%= f.tag(:div) do %>
    n2
    <%= f.input(:first) %>
    <%= f.input(:last) %>
    n3
  <% end %>
  n4
  <%= f.inputs([:first, :last], :legend=>'Foo') %>
  n5
END
    render :inline => <<END
0
<%= forme([:foo, :bar], :action=>'/baz') do |f| %>
  1
  <%= f.tag(:p, {}, 'FBB') %>
  2
  <%= render(:inline =>@nest, :locals=>{:f=>f}) %>
  3
<% end %>
4
END
  end

  def nest_inputs
    @nest = <<END
  n1
  <%= f.inputs do %>
    n2
    <%= f.input(:first) %>
    <%= f.input(:last) %>
    n3
  <% end %>
  n4
  <%= f.inputs([:first, :last], :legend=>'Foo') %>
  n5
END
    render :inline => <<END
0
<%= forme([:foo, :bar], :action=>'/baz') do |f| %>
  1
  <%= f.tag(:p, {}, 'FBB') %>
  2
  <%= render(:inline =>@nest, :locals=>{:f=>f}) %>
  3
<% end %>
4
END
  end

  def nest_seq
    @album = Album.load(:name=>'N', :copies_sold=>2, :id=>1)
    @album.associations[:artist] = Artist.load(:name=>'A', :id=>2)
    @nest = <<END
  n1
  <%= f.subform(:artist) do %>
    n2
    <%= f.input(:name2) %>
    n3
  <% end %>
  n4
  <%= f.subform(:artist, :inputs=>[:name3], :legend=>'Bar') %>
  n5
END
    render :inline => <<END
0
<%= forme(@album, :action=>'/baz') do |f| %>
  1
  <%= f.subform(:artist, :inputs=>[:name], :legend=>'Foo') %>
  2
  <%= render(:inline=>@nest, :locals=>{:f=>f}) %>
  3
<% end %>
4
END
  end

  def hash
    render :inline => "<%= forme({:action=>'/baz'}, :obj=>[:foo]) do |f| %> <%= f.input(:first) %> <% end %>"
  end

  def legend
    render :inline => <<END
<%= forme([:foo, :bar], :action=>'/baz') do |f| %>
  <p>FBB</p>
  <%= f.inputs([:first, :last], :legend=>'Foo') %>
  <p>FBB2</p>
<% end %>
END
  end

  def combined
    render :inline => <<END
<%= forme([:foo, :bar], {:action=>'/baz'}, :inputs=>[:first], :button=>'xyz', :legend=>'123') do |f| %>
  <p>FBB</p>
  <%= f.input(:last) %>
<% end %>
END
  end

  def noblock
    render :inline => "<%= forme([:foo, :bar], {:action=>'/baz'}, :inputs=>[:first], :button=>'xyz', :legend=>'123') %>"
  end

  def noblock_post
    render :inline => "<%= forme({:method=>'post'}, :button=>'xyz') %>"
  end

  def safe_buffer
    render :inline => "<%= forme([:foo, :bar], {:action=>'/baz'}, :inputs=>[:first], :button=>'xyz', :legend=>'<b>foo</b>'.html_safe) %>"
  end
end

describe "Forme Rails integration" do
  def sin_get(path)
    res = FormeRails.call(@rack.merge('PATH_INFO'=>path))
    p res unless res[0] == 200
    res[2].join.gsub(/\s+/, ' ').strip
  end
  before do
    o = Object.new
    def o.puts(*) end
    @rack = {'rack.input'=>'', 'REQUEST_METHOD'=>'GET', 'rack.errors'=>o}
  end

  specify "#form should add start and end tags and yield Forme::Form instance" do
    sin_get('/index').should == '<form action="/baz"> <p>FBB</p> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> <input type="submit" value="Save"/> </form>'
  end

  specify "#form should have inputs work with a block" do
    sin_get('/inputs_block').should == '<form action="/baz"> <fieldset class="inputs"><legend>FBB</legend> <input id="last" name="last" type="text" value="bar"/> </fieldset></form>'
  end

  specify "#form should have inputs with fieldset_ol wrapper work with block" do
    sin_get('/inputs_block_wrapper').should == '<form action="/baz"> <fieldset class="inputs"><legend>FBB</legend><ol> <input id="last" name="last" type="text" value="bar"/> </ol></fieldset></form>'
  end

  specify "#form should add start and end tags and yield Forme::Form instance" do
    sin_get('/nest').should == '<form action="/baz"> <p>FBB</p> <div> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> </div> </form>'
  end

  specify "#form should correctly handle situation where multiple templates are used with same form object" do
    sin_get('/nest_sep').should == "0 <form action=\"/baz\"> 1 <p>FBB</p> 2 n1 <div> n2 <input id=\"first\" name=\"first\" type=\"text\" value=\"foo\"/> <input id=\"last\" name=\"last\" type=\"text\" value=\"bar\"/> n3 </div> n4 <fieldset class=\"inputs\"><legend>Foo</legend><input id=\"first\" name=\"first\" type=\"text\" value=\"foo\"/><input id=\"last\" name=\"last\" type=\"text\" value=\"bar\"/></fieldset> n5 3 </form>4"
  end

  specify "#form should correctly handle situation where multiple templates are used with same form object" do
    sin_get('/nest_inputs').should == "0 <form action=\"/baz\"> 1 <p>FBB</p> 2 n1 <fieldset class=\"inputs\"> n2 <input id=\"first\" name=\"first\" type=\"text\" value=\"foo\"/> <input id=\"last\" name=\"last\" type=\"text\" value=\"bar\"/> n3 </fieldset> n4 <fieldset class=\"inputs\"><legend>Foo</legend><input id=\"first\" name=\"first\" type=\"text\" value=\"foo\"/><input id=\"last\" name=\"last\" type=\"text\" value=\"bar\"/></fieldset> n5 3 </form>4"
  end

  specify "#form should correctly handle situation Sequel integration with subforms where multiple templates are used with same form object" do
    sin_get('/nest_seq').sub(%r{<input name=\"authenticity_token\" type=\"hidden\" value=\"([^\"]+)\"/>}, "<input name=\"authenticity_token\" type=\"hidden\" value=\"csrf\"/>").should == "0 <form action=\"/baz\" class=\"forme album\" method=\"post\"><input name=\"authenticity_token\" type=\"hidden\" value=\"csrf\"/> 1 <input id=\"album_artist_attributes_id\" name=\"album[artist_attributes][id]\" type=\"hidden\" value=\"2\"/><fieldset class=\"inputs\"><legend>Foo</legend><label>Name: <input id=\"album_artist_attributes_name\" name=\"album[artist_attributes][name]\" type=\"text\" value=\"A\"/></label></fieldset> 2 n1 <input id=\"album_artist_attributes_id\" name=\"album[artist_attributes][id]\" type=\"hidden\" value=\"2\"/><fieldset class=\"inputs\"><legend>Artist</legend> n2 <label>Name2: <input id=\"album_artist_attributes_name2\" name=\"album[artist_attributes][name2]\" type=\"text\" value=\"A2\"/></label> n3 </fieldset> n4 <input id=\"album_artist_attributes_id\" name=\"album[artist_attributes][id]\" type=\"hidden\" value=\"2\"/><fieldset class=\"inputs\"><legend>Bar</legend><label>Name3: <input id=\"album_artist_attributes_name3\" name=\"album[artist_attributes][name3]\" type=\"text\" value=\"A3\"/></label></fieldset> n5 3 </form>4"
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

  specify "#form should work without a block with hidden tags" do
    sin_get('/noblock_post').sub(%r{<input name=\"authenticity_token\" type=\"hidden\" value=\"([^\"]+)\"/>}, "<input name=\"authenticity_token\" type=\"hidden\" value=\"csrf\"/>").should == '<form method="post"><input name="authenticity_token" type="hidden" value="csrf"/><input type="submit" value="xyz"/></form>'
  end

  specify "#form should handle Rails SafeBuffers" do
    sin_get('/safe_buffer').should == '<form action="/baz"><fieldset class="inputs"><legend><b>foo</b></legend><input id="first" name="first" type="text" value="foo"/></fieldset><input type="submit" value="xyz"/></form>'
  end
end
end
