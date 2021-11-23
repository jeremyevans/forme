# frozen-string-literal: true

require_relative '../../forme/template'

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
        include ::Forme::Template::Helper

        private

        # Add the csrf and hidden tags options if needed.
        def _forme_form_options(obj, attr, opts)
          super

          apply_csrf = opts[:csrf]

          if apply_csrf || apply_csrf.nil?
            unless method = attr[:method] || attr['method']
              if obj && !obj.is_a?(Hash) && obj.respond_to?(:forme_default_request_method)
                method = obj.forme_default_request_method
              end
            end
          end

          if apply_csrf.nil?
            apply_csrf = csrf_options[:check_request_methods].include?(method.to_s.upcase)
          end

          if apply_csrf
            token = if opts.fetch(:use_request_specific_token){use_request_specific_csrf_tokens?}
              csrf_token(csrf_path(attr[:action]), method)
            else
              csrf_token
            end

            opts[:csrf] = [csrf_field, token]
            opts[:hidden_tags] ||= []
            opts[:hidden_tags] += [{csrf_field=>token}]
          end
        end
      end
    end

    register_plugin(:forme_route_csrf, FormeRouteCsrf)
  end
end
