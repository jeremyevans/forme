require_relative 'shared_erb_specs'

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

  r.get 'nest_seq_simple' do
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
END
    erb <<END
0
<% form(@album, :action=>'/baz') do |f| %>
  1
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

  r.get 'grid-block' do
    @album = Album.load(:name=>'N', :copies_sold=>2, :id=>1)
    @album.associations[:artist] = Artist.load(:name=>'A', :id=>2)
    erb <<END
0
<% form(@album, {:action=>'/baz'}, :button=>'Sub') do |f| %>
  1
  <% f.subform(:artist, :inputs=>[:name], :legend=>'Foo', :grid=>true, :labels=>%w'Name') do %>
    2
  <% end %>
  3
<% end %>
4
END
  end

  r.get 'grid-noblock' do
    @album = Album.load(:name=>'N', :copies_sold=>2, :id=>1)
    @album.associations[:artist] = Artist.load(:name=>'A', :id=>2)
    erb <<END
0
<% form(@album, {:action=>'/baz'}, :button=>'Sub') do |f| %>
  1
  <%= f.subform(:artist, :inputs=>[:name], :legend=>'Foo', :grid=>true, :labels=>%w'Name') %>
  2
<% end %>
3
END
  end

  r.get 'grid-noblock-multiple' do
    @artist = Artist.load(:name=>'A', :id=>2)
    @artist.associations[:albums] = [Album.load(:name=>'N', :copies_sold=>2, :id=>1)]
    erb <<END
0
<% form(@artist, {:action=>'/baz'}, :button=>'Sub') do |f| %>
  1
  <%= f.subform(:albums, :inputs=>[:name, :copies_sold], :legend=>'Foo', :grid=>true, :labels=>%w'Name Copies') %>
  2
<% end %>
3
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

  r.get 'hidden_tags' do
    erb "<%= form([:foo, :bar], {:action=>'/baz'}, :hidden_tags=>[{'a'=>'b'}]) %>"
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
