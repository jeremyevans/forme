require 'rubygems'
require 'sequel'
require 'logger'
$: << ::File.expand_path('../../lib',  __FILE__)

module FormeDemo
DEMO_MODE = !!ENV['DATABASE_URL']
DB = Sequel.connect(ENV['FORME_DATABASE_URL'] || ENV['DATABASE_URL'] || 'sqlite:/')
CREATE_TABLES_FILE = File.join(File.dirname(__FILE__), 'create_tables.rb')

require  ::File.expand_path('../create_tables',  __FILE__)

Model = Class.new(Sequel::Model)
Model.plugin :defaults_setter
Model.plugin :forme
Model.plugin :association_pks
Model.plugin :prepared_statements
Model.plugin :prepared_statements_associations
Dir[::File.expand_path('../models/*.rb',  __FILE__)].each{|f| require f}

def DB.reset
  [:albums_tags, :tags, :tracks, :albums, :artists].each{|t| DB[t].delete}

  artist = Artist.create(:name=>'Elvis')
  album = artist.add_album(:name=>'Elvis Presley', :release_date=>'1956-03-23', :release_party_time=>'1956-03-24 14:05:06', :debut_album=>true, :out_of_print=>false)
  album.add_track(:name=>'Blue Suede Shoes', :number=>1, :length=>2.0)
  album.add_track(:name=>"I'm Counting On You", :number=>2, :length=>2.4)
  rock = album.add_tag(:name=>'Rock & Roll')
  album.add_tag(:name=>'Country')

  album = artist.add_album(:name=>'Blue Hawaii', :release_date=>'1961-10-01', :release_party_time=>'1961-10-02 14:05:06', :debut_album=>false, :out_of_print=>true)
  album.add_track(:name=>'Blue Hawaii', :number=>1, :length=>2.6)
  album.add_track(:name=>"Almost Always True", :number=>2, :length=>2.4)
  album.add_tag(rock)
  album.add_tag(:name=>'Hawaiian')

  artist = Artist.create(:name=>'The Beatles')
  album = artist.add_album(:name=>'Please Please Me', :release_date=>'1963-03-22', :release_party_time=>'1963-03-25 14:05:06', :debut_album=>true, :out_of_print=>false)
  album.add_track(:name=>'I Saw Her Standing There', :number=>1, :length=>2.9)
  album.add_track(:name=>"I'm Counting On You", :number=>2, :length=>2.4)
  album.add_tag(rock)
  pop = album.add_tag(:name=>'Pop')

  album = artist.add_album(:name=>'With The Beatles', :release_date=>'1963-11-22', :release_party_time=>'1963-11-21 14:05:06', :debut_album=>false, :out_of_print=>true)
  album.add_track(:name=>"It Won't Be Long", :number=>1, :length=>2.1)
  album.add_track(:name=>"All I've Got to Do", :number=>2, :length=>2.0)
  album.add_tag(rock)
  album.add_tag(pop)
end

DB.reset

DB.loggers << Logger.new($stdout) unless DEMO_MODE
end
