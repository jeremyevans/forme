# frozen-string-literal: true

require 'forme/erb_form'

class Roda
  module RodaPlugins
    module FormeRouteCsrf
      # Require the render plugin, since forme template integration
      # only makes sense with it.
      def self.load_dependencies(app)
        app.plugin :render
        app.plugin :route_csrf
      end

      module InstanceMethods
        # Create a +Form+ object tied to the current output buffer,
        # using the standard ERB hidden tags.
        def form(obj=nil, attr={}, opts={}, &block)
          if obj.is_a?(Hash)
            attribs = obj
            options = attr = attr.dup
          else
            attribs = attr
            options = opts = opts.dup
          end

          apply_csrf = options[:csrf]

          if apply_csrf || apply_csrf.nil?
            unless method = attribs[:method] || attribs['method']
              if obj && !obj.is_a?(Hash) && obj.respond_to?(:forme_default_request_method)
                method = obj.forme_default_request_method
              end
            end
          end

          if apply_csrf.nil?
            apply_csrf = csrf_options[:check_request_methods].include?(method.to_s.upcase)
          end

          if apply_csrf
            token = if options.fetch(:use_request_specific_token){use_request_specific_csrf_tokens?}
              csrf_token(csrf_path(attribs[:action]), method)
            else
              csrf_token
            end

            options[:hidden_tags] ||= []
            options[:hidden_tags] += [{csrf_field=>token}]
          end

          options[:output] = @_out_buf if block
          ::Forme::ERB::Form.form(obj, attr, opts, &block)
        end
      end
    end

    register_plugin(:forme_route_csrf, FormeRouteCsrf)
  end
end
