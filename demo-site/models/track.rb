module FormeDemo
class Track < Sequel::Model(DB)
  many_to_one :album
end
end
