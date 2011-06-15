class Album < Sequel::Model
  many_to_one :artist
  one_to_many :tracks
  many_to_many :tags

  plugin :nested_attributes
  nested_attributes :artist, :tracks, :tags
end
