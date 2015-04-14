module Forme
  # Empty module for marking objects as "raw", where they will no longer
  # html escaped by the default serializer.
  module Raw
  end

  # A String subclass that includes Raw, which will cause the default
  # serializer to no longer html escape the string.
  class RawString < ::String
    include Raw
  end
end
