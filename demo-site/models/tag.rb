module FormeDemo
class Tag < Sequel::Model(DB)
  many_to_many :albums
end
end
