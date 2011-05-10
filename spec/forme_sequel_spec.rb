require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

require 'rubygems'
require 'sequel'

DB = Sequel.sqlite
DB.create_table(:artists) do
  primary_key :id
  String :name
end
DB.create_table(:albums) do
  primary_key :id
  foreign_key :artist_id, :artists
  String :name
  TrueClass :gold
  TrueClass :platinum, :null=>false, :default=>false
end
DB.create_table(:tracks) do
  primary_key :id
  foreign_key :album_id, :albums
  String :name
end
DB.create_table(:tags) do
  primary_key :id
  String :name
end
DB.create_table(:albums_tags) do
  foreign_key :album_id, :albums
  foreign_key :tag_id, :tags
end

a = DB[:artists].insert(:name=>'a')
d = DB[:artists].insert(:name=>'d')
b = DB[:albums].insert(:name=>'b', :artist_id=>a, :gold=>false)
DB[:tracks].insert(:name=>'m', :album_id=>b)
DB[:tracks].insert(:name=>'n', :album_id=>b)
c = DB[:albums].insert(:name=>'c', :artist_id=>d, :gold=>true, :platinum=>true)
DB[:tracks].insert(:name=>'o', :album_id=>c)
s = DB[:tags].insert(:name=>'s')
t = DB[:tags].insert(:name=>'t')
u = DB[:tags].insert(:name=>'u')
[[b, s], [b, t], [c, t]].each{|k, v| DB[:albums_tags].insert(k, v)}

class Album < Sequel::Model
  plugin :forme
  many_to_one :artist, :order=>:name
  one_to_many :tracks
  many_to_many :tags

  def artist_name
    artist.name if artist
  end
end
class Artist < Sequel::Model; end
class Track < Sequel::Model; end
class Tag < Sequel::Model; end

describe "Forme Sequel::Model forms" do
  before do
    @b = Forme::Form.new(Album[b])
    @c = Forme::Form.new(Album[c])
  end
  
  specify "should use a text field for strings" do
    @b.input(:name).should == '<label>Name: <input id="album_name" name="album[name]" type="text" value="b"/></label>'
    @c.input(:name).should == '<label>Name: <input id="album_name" name="album[name]" type="text" value="c"/></label>'
  end
  
  specify "should use a select box for tri-valued boolean fields" do
    @b.input(:gold).should == '<label>Gold: <select id="album_gold" name="album[gold]"><option></option><option value="t">True</option><option selected="selected" value="f">False</option></select></label>'
    @c.input(:gold).should == '<label>Gold: <select id="album_gold" name="album[gold]"><option></option><option selected="selected" value="t">True</option><option value="f">False</option></select></label>'
  end
  
  specify "should use a checkbox for dual-valued boolean fields" do
    @b.input(:platinum).should == '<label>Platinum: <input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><input id="album_platinum" name="album[platinum]" type="checkbox" value="t"/></label>'
    @c.input(:platinum).should == '<label>Platinum: <input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><input checked="checked" id="album_platinum" name="album[platinum]" type="checkbox" value="t"/></label>'
  end
  
  specify "should use a select box for many_to_one associations" do
    @b.input(:artist).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option></option><option selected="selected" value="1">a</option><option value="2">d</option></select></label>'
    @c.input(:artist).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option></option><option value="1">a</option><option selected="selected" value="2">d</option></select></label>'
  end
  
  specify "should use a text field methods not backed by columns" do
    @b.input(:artist_name).should == '<label>Artist name: <input id="album_artist_name" name="album[artist_name]" type="text" value="a"/></label>'
    @c.input(:artist_name).should == '<label>Artist name: <input id="album_artist_name" name="album[artist_name]" type="text" value="d"/></label>'
  end

  specify "should raise an error for unhandled associations" do
    proc{@b.input(:tracks)}.should raise_error(Forme::Error)
  end
  
  specify "should raise an error for unhandled fields" do
    proc{@b.input(:foo)}.should raise_error(Forme::Error)
  end
end
