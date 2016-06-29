module FormeDemo
class Artist < Model
  one_to_many :albums
  plugin :nested_attributes
  nested_attributes :albums
end
end
