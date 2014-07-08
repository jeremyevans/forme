require 'forme'

module Forme
  module Sinatra
    HIDDEN_TAGS = []

    # Add a hidden tag proc that will be used for all forms created via Forme::Sinatra::ERB#form.
    # The block is yielded the Forme::Tag object for the form tag.
    # The block should return either nil if hidden tag should be added, or a Forme::Tag object (or an array of them),
    # or a hash with keys specifying the name of the tags and the values specifying the values of the tags .
    def self.add_hidden_tag(&block)
      HIDDEN_TAGS << block
    end

    # Add CSRF token tag by default for POST forms
    add_hidden_tag do |tag|
      if defined?(::Rack::Csrf) && (form = tag.form) && (env = form.opts[:env]) && tag.attr[:method].to_s.upcase == 'POST'
        {::Rack::Csrf.field=>::Rack::Csrf.token(env)}
      end
    end

    # Subclass used when using Forme/Sinatra ERB integration.
    # Handles integrating into the view template so that
    # methods with blocks can inject strings into the output.
    class Form < ::Forme::Form
      # Template output object, where serialized output gets
      # injected.
      attr_reader :output

      # Set the template output object when initializing.
      def initialize(*)
        super
        @output = @opts[:output] ? @opts[:output] : ''
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
            emit(serializer.serialize_open(tag)) if serializer.respond_to?(:serialize_open)
            Array(tag.children).each{|c| emit(c)}
            yield self
            emit(serializer.serialize_close(tag)) if serializer.respond_to?(:serialize_close)
          end
        else
          tag
        end
      end

      def capture(block='')
        buf_was, @output = @output, block.is_a?(Proc) ? (eval("@_out_buf", block.binding) || @output) : block
        yield
        ret = @output
        @output = buf_was
        ret
      end
    end
    
    # This is the module used to add the Forme integration
    # to Sinatra.  It should be enabled in Sinatra with the
    # following code in your <tt>Sinatra::Base</tt> subclass:
    #
    #   helpers Forme::Sinatra::ERB
    module ERB
      # Create a +Form+ object tied to the current output buffer,
      # using the standard sinatra hidden tags.
      def form(obj=nil, attr={}, opts={}, &block)
        if block
          h = {:output=>@_out_buf, :hidden_tags=>Forme::Sinatra::HIDDEN_TAGS, :env=>env}
          (obj.is_a?(Hash) ? attr = attr.merge(h) : opts = opts.merge(h))
          Form.form(obj, attr, opts, &block)
        else
          Form.form(obj, attr, opts)
        end
      end
    end 

    # Alias of <tt>Forme::Sinatra::ERB</tt>
    Erubis = ERB
  end
end
