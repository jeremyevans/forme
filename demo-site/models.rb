require 'rubygems'
require 'sequel'
require 'logger'
$: << '../lib'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite:/')
DB.loggers << Logger.new($stdout) unless ENV['DATABASE_URL']

DB.create_table!(:artists) do
  primary_key :id
  String :name, :null=>false, :unique=>true
end
'A B C'.split.each{|x| DB[:artists].insert(:name=>x)}

DB.create_table!(:albums) do
  primary_key :id
  String :name, :null=>false
  foreign_key :artist_id, :artists, :null=>false
  Date :release_date, :null=>false
  DateTime :created_at, :null=>false, :default=>'now()'
  DateTime :updated_at
  Integer :copies_sold, :null=>false, :default=>0
  TrueClass :debut_album, :null=>false
  TrueClass :out_of_print
  index [:name, :artist_id], :unique=>true
end
DB[:albums].insert(:name=>'J', :artist_id=>1, :release_date=>'1979-01-02', :debut_album=>true, :out_of_print=>false)
DB[:albums].insert(:name=>'K', :artist_id=>2, :release_date=>'1980-03-02', :debut_album=>false, :out_of_print=>true)

DB.create_table!(:tracks) do
  primary_key :id
  Integer :number, :null=>false
  String :name, :null=>false
  foreign_key :album_id, :albums, :null=>false
  Float :length
end
DB[:tracks].insert(:name=>'R', :number=>1, :album_id=>1, :length=>3.2)
DB[:tracks].insert(:name=>'S', :number=>2, :album_id=>1, :length=>6.4)
DB[:tracks].insert(:name=>'T', :number=>1, :album_id=>2, :length=>0.1)
DB[:tracks].insert(:name=>'U', :number=>2, :album_id=>2, :length=>0.2)

DB.create_table!(:tags) do
  primary_key :id
  String :name, :null=>false, :unique=>true
end
'X Y Z'.split.each{|x| DB[:tags].insert(:name=>x)}

DB.create_table!(:albums_tags) do
  foreign_key :album_id, :albums
  foreign_key :tag_id, :tags
  primary_key [:album_id, :tag_id]
end
DB[:albums_tags].insert(1, 1)
DB[:albums_tags].insert(1, 2)
DB[:albums_tags].insert(2, 3)

Sequel::Model.plugin :defaults_setter
Sequel::Model.plugin :forme
Dir['models/*.rb'].each{|f| require f}
