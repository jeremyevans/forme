require 'forme'

module Forme
  module Rails # :nodoc:
    # Subclass used when using Forme/Rails ERB integration,
    # handling integration with the view template.
    class Form < ::Forme::Form
      # The Rails template that created this form.
      attr_reader :template

      # Set the template object when initializing.
      def initialize(*)
        super
        @template = @opts[:template]
      end

      # Serialize and mark as already escaped the string version of
      # the input.
      def emit(tag)
        template.output_buffer << template.raw(tag.to_s)
      end

      # Capture the inputs into a new output buffer, and return
      # the buffer if not given a block
      def inputs(*)
        if block_given?
          super
        else
          template.send(:with_output_buffer){super}
        end
      end
      
      # If a block is not given, emit the inputs into the current output
      # buffer.
      def _inputs(*)
        if block_given?
          super
        else
          emit(super)
        end
      end

      # Return a string version of the input that is already marked as safe.
      def input(*)
        template.raw(super.to_s)
      end

      # Return a string version of the button that is already marked as safe.
      def button(*)
        template.raw(super.to_s)
      end

      # If a block is given, create a new output buffer and make sure all the
      # output of the tag goes into that buffer, and return the buffer.
      # Otherwise, just return a string version of the tag that is already
      # marked as safe.
      def tag(type, attr={}, children=[], &block)
        if block_given?
          template.send(:with_output_buffer){tag_(type, attr, children, &block)}
        else
          tag = _tag(type, attr, children)
          template.raw(tag.to_s)
        end
      end

      def tag_(type, attr={}, children=[])
        tag = _tag(type, attr, children)
        emit(serializer.serialize_open(tag)) if serializer.respond_to?(:serialize_open)
        Array(children).each{|c| emit(c)}
        yield self if block_given?
        emit(serializer.serialize_close(tag)) if serializer.respond_to?(:serialize_close)
      end
    end

    module ERB
      # Create a +Form+ object and yield it to the block,
      # injecting the opening form tag before yielding and
      # the closing form tag after yielding.
      #
      # Argument Handling:
      # No args :: Creates a +Form+ object with no options and not associated
      #            to an +obj+, and with no attributes in the opening tag.
      # 1 hash arg :: Treated as opening form tag attributes, creating a
      #               +Form+ object with no options.
      # 1 non-hash arg :: Treated as the +Form+'s +obj+, with empty options
      #                   and no attributes in the opening tag.
      # 2 hash args :: First hash is opening attributes, second hash is +Form+
      #                options.
      # 1 non-hash arg, 1-2 hash args :: First argument is +Form+'s obj, second is
      #                                  opening attributes, third if provided is
      #                                  +Form+'s options.
      def forme(obj=nil, attr={}, opts={}, &block)
        h = {:template=>self}
        (obj.is_a?(Hash) ? attr = attr.merge(h) : opts = opts.merge(h))
        Form.form(obj, attr, opts, &block)
      end
    end
  end
end
