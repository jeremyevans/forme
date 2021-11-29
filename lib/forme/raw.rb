# frozen-string-literal: true

module Forme
  # Empty module for marking objects as "raw", where they will no longer
  # HTML escaped by the default serializer.
  module Raw
  end

  # A String subclass that includes Raw, which will cause the default
  # serializer to no longer HTML escape the string.
  class RawString < ::String
    include Raw
  end
end
