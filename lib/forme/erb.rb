# frozen-string-literal: true

require 'forme/erb_form'

module Forme
  module ERB 
    HIDDEN_TAGS = []

    # Add a hidden tag proc that will be used for all forms created via Forme::ERB::Helper#form.
    # The block is yielded the Forme::Tag object for the form tag.
    # The block should return either nil if hidden tag should be added, or a Forme::Tag object (or an array of them),
    # or a hash with keys specifying the name of the tags and the values specifying the values of the tags .
    def self.add_hidden_tag(&block)
      HIDDEN_TAGS << block
    end

    # Add CSRF token tag by default for POST forms
    add_hidden_tag do |tag|
      if defined?(::Rack::Csrf) && (form = tag.form) && (env = form.opts[:env]) && env['rack.session'] && (tag.attr[:method] || tag.attr['method']).to_s.upcase == 'POST'
        {::Rack::Csrf.field=>::Rack::Csrf.token(env)}
      end
    end

    # This is the module used to add the Forme integration
    # to ERB.
    module Helper 
      # Create a +Form+ object tied to the current output buffer,
      # using the standard ERB hidden tags.
      def form(obj=nil, attr={}, opts={}, &block)
        h = {:hidden_tags=>Forme::ERB::HIDDEN_TAGS, :env=>env}
        h[:output] = @_out_buf if block
        (obj.is_a?(Hash) ? attr = attr.merge(h) : opts = opts.merge(h))
        Form.form(obj, attr, opts, &block)
      end
    end 
  end
end
