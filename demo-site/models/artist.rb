module FormeDemo
class Artist < Sequel::Model(DB)
  one_to_many :albums
  plugin :nested_attributes
  nested_attributes :albums
end
end
