# frozen-string-literal: true

require 'forme'

module Forme
  module ERB 
    # Subclass used when using Forme ERB integration.
    # Handles integrating into the view template so that
    # methods with blocks can inject strings into the output.
    class Form < ::Forme::Form
      # Template output object, where serialized output gets
      # injected.
      attr_reader :output

      # Set the template output object when initializing.
      def initialize(*)
        super
        @output = @opts[:output] ? @opts[:output] : String.new
      end

      # Serialize the tag and inject it into the output.
      def emit(tag)
        output << tag.to_s
      end

      # Capture the inside of the inputs, injecting it into the template
      # if a block is given, or returning it as a string if not.
      def inputs(*a, &block)
        if block
          capture(block){super}
        else
          capture{super}
        end
      end

      # Capture the inside of the form, injecting it into the template if
      # a block is given, or returning it as a string if not.
      def form(*a, &block)
        if block
          capture(block){super}
        else
          super
        end
      end

      # If a block is given, inject an opening tag into the
      # output, inject any given children into the output, yield to the
      # block, inject a closing tag into the output.
      # If a block is not given, just return the tag created.
      def tag(type, attr={}, children=[], &block)
        tag = _tag(type, attr, children)
        if block
          capture(block) do
            emit(serialize_open(tag))
            Array(tag.children).each{|c| emit(c)}
            yield self
            emit(serialize_close(tag))
          end
        else
          tag
        end
      end

      def capture(block=String.new) # :nodoc:
        buf_was, @output = @output, block.is_a?(Proc) ? (eval("@_out_buf", block.binding) || @output) : block
        yield
        ret = @output
        @output = buf_was
        ret
      end
    end
  end
end

