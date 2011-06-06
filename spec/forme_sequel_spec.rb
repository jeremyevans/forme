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
class Artist < Sequel::Model
  def idname() "#{id}#{name}" end
end
class Track < Sequel::Model; end
class Tag < Sequel::Model; end

describe "Forme Sequel::Model forms" do
  before do
    @ab = Album[b]
    @b = Forme::Form.new(@ab)
    @ac = Album[c]
    @c = Forme::Form.new(@ac)
  end
  
  specify "should use a text field for strings" do
    @b.input(:name).should == '<label>Name: <input id="album_name" name="album[name]" type="text" value="b"/></label>'
    @c.input(:name).should == '<label>Name: <input id="album_name" name="album[name]" type="text" value="c"/></label>'
  end
  
  specify "should allow :type=>:textarea to use a textarea" do
    @b.input(:name, :type=>:textarea).should == '<label>Name: <textarea id="album_name" name="album[name]">b</textarea></label>'
    @c.input(:name, :type=>:textarea).should == '<label>Name: <textarea id="album_name" name="album[name]">c</textarea></label>'
  end
  
  specify "should use a select box for tri-valued boolean fields" do
    @b.input(:gold).should == '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option value="t">True</option><option selected="selected" value="f">False</option></select></label>'
    @c.input(:gold).should == '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option selected="selected" value="t">True</option><option value="f">False</option></select></label>'
  end
  
  specify "should use a checkbox for dual-valued boolean fields" do
    @b.input(:platinum).should == '<label>Platinum: <input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><input id="album_platinum" name="album[platinum]" type="checkbox" value="t"/></label>'
    @c.input(:platinum).should == '<label>Platinum: <input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><input checked="checked" id="album_platinum" name="album[platinum]" type="checkbox" value="t"/></label>'
  end
  
  specify "should use a select box for many_to_one associations" do
    @b.input(:artist).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select></label>'
    @c.input(:artist).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a</option><option selected="selected" value="2">d</option></select></label>'
  end
  
  specify "should use a set of radio buttons for many_to_one associations with :type=>:radio option" do
    @b.input(:artist, :type=>:radio).should == 'Artist: <label><input checked="checked" name="album[artist_id]" type="radio" value="1"/> a</label><label><input name="album[artist_id]" type="radio" value="2"/> d</label>'
    @c.input(:artist, :type=>:radio).should == 'Artist: <label><input name="album[artist_id]" type="radio" value="1"/> a</label><label><input checked="checked" name="album[artist_id]" type="radio" value="2"/> d</label>'
  end
  
  specify "should respect an :options entry" do
    @b.input(:artist, :options=>Artist.order(:name).map{|a| [a.name, a.id+1]}).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="2">a</option><option value="3">d</option></select></label>'
    @c.input(:artist, :options=>Artist.order(:name).map{|a| [a.name, a.id+1]}).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="2">a</option><option value="3">d</option></select></label>'
  end
  
  specify "should support :name_method option for choosing name method" do
    @b.input(:artist, :name_method=>:idname).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">1a</option><option value="2">2d</option></select></label>'
    @c.input(:artist, :name_method=>:idname).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">1a</option><option selected="selected" value="2">2d</option></select></label>'
  end
  
  specify "should try a list of methods to get a suitable one for select box naming" do
    al = Class.new(Album){def self.name() 'Album' end}
    ar = Class.new(Artist)
    al.many_to_one :artist, :class=>ar
    ar.class_eval{undef_method(:name)}
    f = Forme::Form.new(al.new)

    ar.class_eval{def number() "#{self[:name]}1" end}
    f.input(:artist).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a1</option><option value="2">d1</option></select></label>'

    ar.class_eval{def title() "#{self[:name]}2" end}
    f.input(:artist).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a2</option><option value="2">d2</option></select></label>'

    ar.class_eval{def name() "#{self[:name]}3" end}
    f.input(:artist).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a3</option><option value="2">d3</option></select></label>'

    ar.class_eval{def forme_name() "#{self[:name]}4" end}
    f.input(:artist).should == '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a4</option><option value="2">d4</option></select></label>'
  end
  
  specify "should raise an error when using an association without a usable name method" do
    al = Class.new(Album)
    ar = Class.new(Artist)
    al.many_to_one :artist, :class=>ar
    ar.class_eval{undef_method(:name)}
    proc{Forme::Form.new(al.new).input(:artist)}.should raise_error(Forme::Error)
  end
    
  specify "should use a multiple select box for one_to_many associations" do
    @b.input(:tracks).should == '<label>Tracks: <select id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option selected="selected" value="1">m</option><option selected="selected" value="2">n</option><option value="3">o</option></select></label>'
    @c.input(:tracks).should == '<label>Tracks: <select id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option value="1">m</option><option value="2">n</option><option selected="selected" value="3">o</option></select></label>'
  end
  
  specify "should use a multiple select box for many_to_many associations" do
    @b.input(:tags).should == '<label>Tags: <select id="album_tag_pks" multiple="multiple" name="album[tag_pks][]"><option selected="selected" value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></label>'
    @c.input(:tags).should == '<label>Tags: <select id="album_tag_pks" multiple="multiple" name="album[tag_pks][]"><option value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></label>'
  end

  specify "should use multiple checkboxes for one_to_many associations if :type=>:checkbox" do
    @b.input(:tracks, :type=>:checkbox).should == 'Tracks: <label><input checked="checked" name="album[track_pks][]" type="checkbox" value="1"/> m</label><label><input checked="checked" name="album[track_pks][]" type="checkbox" value="2"/> n</label><label><input name="album[track_pks][]" type="checkbox" value="3"/> o</label>'
    @c.input(:tracks, :type=>:checkbox).should == 'Tracks: <label><input name="album[track_pks][]" type="checkbox" value="1"/> m</label><label><input name="album[track_pks][]" type="checkbox" value="2"/> n</label><label><input checked="checked" name="album[track_pks][]" type="checkbox" value="3"/> o</label>'
  end
  
  specify "should use multiple checkboxes for many_to_many associations if :type=>:checkbox" do
    @b.input(:tags, :type=>:checkbox).should == 'Tags: <label><input checked="checked" name="album[tag_pks][]" type="checkbox" value="1"/> s</label><label><input checked="checked" name="album[tag_pks][]" type="checkbox" value="2"/> t</label><label><input name="album[tag_pks][]" type="checkbox" value="3"/> u</label>'
    @c.input(:tags, :type=>:checkbox).should == 'Tags: <label><input name="album[tag_pks][]" type="checkbox" value="1"/> s</label><label><input checked="checked" name="album[tag_pks][]" type="checkbox" value="2"/> t</label><label><input name="album[tag_pks][]" type="checkbox" value="3"/> u</label>'
  end

  specify "should use a text field methods not backed by columns" do
    @b.input(:artist_name).should == '<label>Artist name: <input id="album_artist_name" name="album[artist_name]" type="text" value="a"/></label>'
    @c.input(:artist_name).should == '<label>Artist name: <input id="album_artist_name" name="album[artist_name]" type="text" value="d"/></label>'
  end

  specify "should correctly show an error message if there is one" do
    @ab.errors.add(:name, 'tis not valid')
    @b.input(:name).should == '<label>Name: <input class="error" id="album_name" name="album[name]" type="text" value="b"/><span class="error_message">tis not valid</span></label>'
  end
  
  specify "should correctly show an error message for many_to_one associations if there is one" do
    @ab.errors.add(:artist_id, 'tis not valid')
    @b.input(:artist).should == '<label>Artist: <select class="error" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select><span class="error_message">tis not valid</span></label>'
  end
  
  specify "should raise an error for unhandled associations" do
    al = Class.new(Album)
    al.association_reflection(:tags)[:type] = :foo
    proc{Forme::Form.new(al.new).input(:tags)}.should raise_error(Forme::Error)
  end
  
  specify "should raise an error for unhandled fields" do
    proc{@b.input(:foo)}.should raise_error(Forme::Error)
  end

  specify "should add required attribute if the column doesn't support nil values" do
    def @ab.db_schema; h = super.dup; h[:name] = h[:name].merge(:allow_null=>false); h end
    @b.input(:name).should == '<label>Name: <input id="album_name" name="album[name]" required="required" type="text" value="b"/></label>'
  end
  
end
