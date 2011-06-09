require 'forme'

module Forme
  module Sinatra # :nodoc:
    # Subclass used when using Forme/Sinatra ERB integration.
    # Handles integrating into the view template so that
    # methods with blocks can inject strings into the output.
    class Form < ::Forme::Form
      attr_reader :output

      def emit(tag)
        output << tag.to_s
      end

      def inputs(*a)
        super
        nil
      end

      def form(*a, &block)
        @output = eval('@_out_buf', block.binding)
        super
      end

      # If a block is provided and no children are present,
      # inject an opening tag into the output, yield to the
      # block, and then inject a closing tag into the output.
      def tag(type, attr={}, children=[])
        tag = _tag(type, attr, children)
        if block_given?
          emit serializer.serialize_open(tag)
          children.each{|c| emit(c)}
          yield self
          emit serializer.serialize_close(tag)
        else
          serialize(tag)
        end
      end
    end
    
    # This is the module used to add the Forme integration
    # to Sinatra.  It should be enabled in Sinatra with the
    # following code in your <tt>Sinatra::Base</tt> subclass:
    #
    #   helpers Forme::Sinatra::ERB
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
      def form(*a, &block)
        Form.form(*a, &block)
      end
    end 
    Erubis = ERB
  end
end
