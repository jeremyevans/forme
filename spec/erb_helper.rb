ERB_BLOCK = lambda do |r|
  r.get '' do
    erb <<END
<% form([:foo, :bar], :action=>'/baz') do |f| %>
  <p>FBB</p>
  <%= f.input(:first) %>
  <%= f.input(:last) %>
  <%= f.button('Save') %>
<% end %>
END
  end

  r.get 'inputs_block' do
    erb <<END
<% form([:foo, :bar], :action=>'/baz') do |f| %><% f.inputs(:legend=>'FBB') do %>
    <%= f.input(:last) %>
  <% end %><% end %>
END
  end

  r.get 'inputs_block_wrapper' do
    erb <<END
<% form([:foo, :bar], {:action=>'/baz'}, :inputs_wrapper=>:fieldset_ol) do |f| %><% f.inputs(:legend=>'FBB') do %>
    <%= f.input(:last) %>
  <% end %><% end %>
END
  end

  r.get 'nest' do
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

  r.get 'nest_sep' do
    @nest = <<END
  n1
  <% f.tag(:div) do %>
    n2
    <%= f.input(:first) %>
    <%= f.input(:last) %>
    n3
  <% end %>
  n4
  <%= f.inputs([:first, :last], :legend=>'Foo') %>
  n5
END
    erb <<END
0
<% form([:foo, :bar], :action=>'/baz') do |f| %>
  1
  <%= f.tag(:p, {}, 'FBB') %>
  2
  <%= erb(@nest, :locals=>{:f=>f}) %>
  3
<% end %>
4
END
  end

  r.get 'nest_seq' do
    @album = Album.load(:name=>'N', :copies_sold=>2, :id=>1)
    @album.associations[:artist] = Artist.load(:name=>'A', :id=>2)
    @nest = <<END
  n1
  <% f.subform(:artist) do %>
    n2
    <%= f.input(:name2) %>
    n3
  <% end %>
  n4
  <%= f.subform(:artist, :inputs=>[:name3], :legend=>'Bar') %>
  n5
END
    erb <<END
0
<% form(@album, :action=>'/baz') do |f| %>
  1
  <%= f.subform(:artist, :inputs=>[:name], :legend=>'Foo') %>
  2
  <%= erb(@nest, :locals=>{:f=>f}) %>
  3
<% end %>
4
END
  end

  r.get 'hash' do
    erb "<% form({:action=>'/baz'}, :obj=>[:foo]) do |f| %> <%= f.input(:first) %> <% end %>"
  end

  r.get 'legend' do
    erb <<END
<% form([:foo, :bar], :action=>'/baz') do |f| %>
  <p>FBB</p>
  <%= f.inputs([:first, :last], :legend=>'Foo') %>
  <p>FBB2</p>
<% end %>
END
  end

  r.get 'combined' do
    erb <<END
<% form([:foo, :bar], {:action=>'/baz'}, :inputs=>[:first], :button=>'xyz', :legend=>'123') do |f| %>
  <p>FBB</p>
  <%= f.input(:last) %>
<% end %>
END
  end

  r.get 'noblock' do
    erb "<%= form([:foo, :bar], {:action=>'/baz'}, :inputs=>[:first], :button=>'xyz', :legend=>'123') %>"
  end

  r.get 'noblock_post' do
    erb "<%= form({:method=>:post}, :button=>'xyz') %>"
  end

  r.get 'noblock_empty' do
    erb "<%= form(:action=>'/baz') %>"
  end
end

shared_examples_for "erb integration" do
  before do
    o = Object.new
    def o.puts(*) end
    @rack = {'rack.input'=>'', 'REQUEST_METHOD'=>'GET', 'rack.errors'=>o, 'SCRIPT_NAME'=>''}
  end

  specify "#form should add start and end tags and yield Forme::Form instance" do
    sin_get('/').should == '<form action="/baz"> <p>FBB</p> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> <input type="submit" value="Save"/> </form>'
  end

  specify "#form should have inputs work with a block" do
    sin_get('/inputs_block').should == '<form action="/baz"><fieldset class="inputs"><legend>FBB</legend> <input id="last" name="last" type="text" value="bar"/> </fieldset></form>'
  end

  specify "#form should have inputs with fieldset_ol wrapper work with block" do
    sin_get('/inputs_block_wrapper').should == '<form action="/baz"><fieldset class="inputs"><legend>FBB</legend><ol> <input id="last" name="last" type="text" value="bar"/> </ol></fieldset></form>'
  end

  specify "#form should add start and end tags and yield Forme::Form instance" do
    sin_get('/nest').should == '<form action="/baz"> <p>FBB</p> <div> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> </div> </form>'
  end

  specify "#form should correctly handle situation where multiple templates are used with same form object" do
    sin_get('/nest_sep').should == "0 <form action=\"/baz\"> 1 <p>FBB</p> 2 n1 <div> n2 <input id=\"first\" name=\"first\" type=\"text\" value=\"foo\"/> <input id=\"last\" name=\"last\" type=\"text\" value=\"bar\"/> n3 </div> n4 <fieldset class=\"inputs\"><legend>Foo</legend><input id=\"first\" name=\"first\" type=\"text\" value=\"foo\"/><input id=\"last\" name=\"last\" type=\"text\" value=\"bar\"/></fieldset> n5 3 </form>4"
  end

  specify "#form should correctly handle situation Sequel integration with subforms where multiple templates are used with same form object" do
    sin_get('/nest_seq').sub(%r{<input name=\"_csrf\" type=\"hidden\" value=\"([^\"]+)\"/>}, "<input name=\"_csrf\" type=\"hidden\" value=\"csrf\"/>").should == "0 <form action=\"/baz\" class=\"forme album\" method=\"post\"><input name=\"_csrf\" type=\"hidden\" value=\"csrf\"/> 1 <input id=\"album_artist_attributes_id\" name=\"album[artist_attributes][id]\" type=\"hidden\" value=\"2\"/><fieldset class=\"inputs\"><legend>Foo</legend><label>Name: <input id=\"album_artist_attributes_name\" name=\"album[artist_attributes][name]\" type=\"text\" value=\"A\"/></label></fieldset> 2 n1 <input id=\"album_artist_attributes_id\" name=\"album[artist_attributes][id]\" type=\"hidden\" value=\"2\"/><fieldset class=\"inputs\"><legend>Artist</legend> n2 <label>Name2: <input id=\"album_artist_attributes_name2\" name=\"album[artist_attributes][name2]\" type=\"text\" value=\"A2\"/></label> n3 </fieldset> n4 <input id=\"album_artist_attributes_id\" name=\"album[artist_attributes][id]\" type=\"hidden\" value=\"2\"/><fieldset class=\"inputs\"><legend>Bar</legend><label>Name3: <input id=\"album_artist_attributes_name3\" name=\"album[artist_attributes][name3]\" type=\"text\" value=\"A3\"/></label></fieldset> n5 3 </form>4"
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

  specify "#form should work without a block and still have hidden tags emitted" do
    sin_get('/noblock_post').sub(%r{<input name=\"_csrf\" type=\"hidden\" value=\"([^\"]+)\"/>}, "<input name=\"_csrf\" type=\"hidden\" value=\"csrf\"/>").should == '<form method="post"><input name="_csrf" type="hidden" value="csrf"/><input type="submit" value="xyz"/></form>'
  end

  specify "#form with an empty form should work" do
    sin_get('/noblock_empty').should == '<form action="/baz"></form>'
  end
end
