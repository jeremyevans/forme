require 'rubygems'
require 'sequel'
require 'logger'
$: << '../lib'

DEMO_MODE = !!ENV['DATABASE_URL']
DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite:/')
DB.loggers << Logger.new($stdout) unless DEMO_MODE

DB.create_table!(:artists) do
  primary_key :id
  String :name, :null=>false, :unique=>true
end
1.upto(3){|x| DB[:artists].insert(:name=>"Example Artist #{x}")}

DB.create_table!(:albums) do
  primary_key :id
  String :name, :null=>false
  foreign_key :artist_id, :artists, :null=>false
  Date :release_date, :null=>false
  DateTime :release_party_time, :null=>false
  Integer :copies_sold, :null=>false, :default=>0
  TrueClass :debut_album, :null=>false
  TrueClass :out_of_print
  index [:name, :artist_id], :unique=>true
end
DB[:albums].insert(:name=>'Example Album', :artist_id=>1, :release_date=>'1979-01-02', :release_party_time=>'1979-01-03 04:05:06', :debut_album=>true, :out_of_print=>false)

DB.create_table!(:tracks) do
  primary_key :id
  Integer :number, :null=>false
  String :name, :null=>false
  foreign_key :album_id, :albums
  Float :length
end
DB[:tracks].insert(:name=>'Example Track 1', :number=>1, :album_id=>1, :length=>3.2)
DB[:tracks].insert(:name=>'Example Track 2', :number=>2, :album_id=>1, :length=>6.4)
DB[:tracks].insert(:name=>'Example Track 3', :number=>1, :length=>0.1)
DB[:tracks].insert(:name=>'Example Track 4', :number=>2, :length=>0.2)

DB.create_table!(:tags) do
  primary_key :id
  String :name, :null=>false, :unique=>true
end
1.upto(3){|x| DB[:tags].insert(:name=>"Example Tag #{x}")}

DB.create_table!(:albums_tags) do
  foreign_key :album_id, :albums
  foreign_key :tag_id, :tags
  primary_key [:album_id, :tag_id]
end
DB[:albums_tags].insert(1, 1)
DB[:albums_tags].insert(1, 2)

Sequel::Model.plugin :defaults_setter
Sequel::Model.plugin :forme
Sequel::Model.plugin :association_pks
Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :prepared_statements_associations
Dir['models/*.rb'].each{|f| require f}
