DB.create_table?(:artists) do
  primary_key :id
  String :name, :null=>false, :unique=>true
end

DB.create_table?(:albums) do
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

DB.create_table?(:tracks) do
  primary_key :id
  Integer :number, :null=>false
  String :name, :null=>false
  foreign_key :album_id, :albums
  Float :length
end

DB.create_table?(:tags) do
  primary_key :id
  String :name, :null=>false, :unique=>true
end

DB.create_table?(:albums_tags) do
  foreign_key :album_id, :albums
  foreign_key :tag_id, :tags
  primary_key [:album_id, :tag_id]
end
