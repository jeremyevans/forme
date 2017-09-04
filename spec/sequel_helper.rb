require 'rubygems'
require 'sequel'

db_url = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' ? 'jdbc:sqlite::memory:' : 'sqlite:/'
DB = Sequel.connect(db_url, :identifier_mangling=>false)
DB.extension(:freeze_datasets)
Sequel.default_timezone = :utc
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
  Date :release_date
  DateTime :created_at
  Integer :copies_sold
end
DB.create_table(:album_infos) do
  primary_key :id
  foreign_key :album_id, :albums
  String :info
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
b = DB[:albums].insert(:name=>'b', :artist_id=>a, :gold=>false, :release_date=>Date.new(2011, 6, 5), :created_at=>Date.new(2011, 6, 5), :copies_sold=>10)
DB[:tracks].insert(:name=>'m', :album_id=>b)
DB[:tracks].insert(:name=>'n', :album_id=>b)
c = DB[:albums].insert(:name=>'c', :artist_id=>d, :gold=>true, :platinum=>true)
DB[:tracks].insert(:name=>'o', :album_id=>c)
s = DB[:tags].insert(:name=>'s')
t = DB[:tags].insert(:name=>'t')
DB[:tags].insert(:name=>'u')
[[b, s], [b, t], [c, t]].each{|k, v| DB[:albums_tags].insert(k, v)}

# Allow loading of pg_array extension even when not on PostgreSQL
def DB.add_conversion_proc(*)
  super if defined?(super)
end
def DB.conversion_procs_updated(*)
  super if defined?(super)
end
def DB.conversion_procs
  return super if defined?(super)
  {}
end

Sequel::Model.plugin :forme
class Album < Sequel::Model
  plugin :association_pks
  plugin :forme_set

  many_to_one :artist, :order=>:name
  one_to_one :album_info
  one_to_many :tracks
  many_to_many :tags, :delay_pks=>:always

  plugin :pg_array_associations
  pg_array_to_many :atags, :class=>:Tag

  def atag_ids
    @atag_ids ||= [1,2]
  end

  def artist_name
    artist.name if artist
  end

  alias foo= name=

  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    # Add workaround for no boolean handling in jdbc-sqlite3
    plugin :typecast_on_load, :gold, :platinum, :release_date, :created_at
  end
end
class Artist < Sequel::Model
  one_to_many :albums
  def idname() "#{id}#{name}" end
  def name2() "#{name}2" end
  def name3() "#{name}3" end
end
class Track < Sequel::Model; end
class Tag < Sequel::Model; end
class AlbumInfo < Sequel::Model; end

