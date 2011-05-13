require 'forme'

module Forme
  module Sinatra # :nodoc:
    # Subclass used when using Forme/Sinatra ERB integration.
    # Handles integrating into the view template so that
    # methods with blocks can inject strings into the output.
    class Form < ::Forme::Form
      # If a block is provided and no children are present,
      # inject an opening tag into the output, yield to the
      # block, and then inject a closing tag into the output.
      def tag(type, attr={}, children=[], &block)
        tag = Tag.new(type, attr, children)
        if block && children.empty?
          output = eval('@_out_buf', block.binding)
          output << serializer.serialize_open(tag)
          yield self
          output << serializer.serialize_close(tag)
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
      def form(obj=nil, attr={}, opts={}, &block)
        if obj.is_a?(Hash)
          raise Error, "Can't provide 3 hash arguments to form" unless opts.empty?
          opts = attr
          attr = obj
          Form.new(opts).tag(:form, attr, &block)
        else
          Form.new(obj, opts).tag(:form, attr, &block)
        end
      end
    end 
    Erubis = ERB
  end
end
