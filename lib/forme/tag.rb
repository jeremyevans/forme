# frozen-string-literal: true

module Forme
  # Low level abstract tag form, where each instance represents an
  # HTML tag with attributes and children.
  class Tag
    # The +Form+ object related to the receiver.
    attr_reader :form

    # The type of tag, should be a symbol (e.g. :input, :select).
    attr_reader :type
    
    # The attributes hash of this receiver.
    attr_reader :attr

    # An array instance representing the children of the receiver,
    # or possibly +nil+ if the receiver has no children.
    attr_reader :children

    # Set the +form+, +type+, +attr+, and +children+.
    def initialize(form, type, attr={}, children=nil, &block)
      @form, @type, @attr = form, type, (attr||{})
      @children = parse_children(children||block)
    end

    # Create a new +Tag+ instance with the given arguments and block
    # related to the receiver's +form+.
    def tag(*a, &block)
      form._tag(*a, &block)
    end

    # Return a string containing the serialized content of the receiver.
    def to_s
      Forme.transform(:serializer, @opts, @form.opts, self)
    end

    private

    # Convert children constructor argument into the children to use for the tag.
    def parse_children(children)
      case children
      when Array
        children
      when Proc, Method
        parse_children(children.call(self))
      when nil
        nil
      else
        [children]
      end
    end
  end
end
