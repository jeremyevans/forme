# frozen-string-literal: true

require_relative 'template'

module Forme
  module ERB 
    # This is the module used to add the Forme integration to ERB templates, with optional support for
    # rack_csrf for CSRF handling.
    module Helper 
      include Template::Helper

      private

      def _forme_form_options(obj, attr, opts)
        super

        if defined?(::Rack::Csrf) && env['rack.session']
          opts[:_before_post] = lambda do |form|
            form.tag(:input, :type=>:hidden, :name=>::Rack::Csrf.field, :value=>::Rack::Csrf.token(env))
          end
        end
      end
    end 
  end
end
