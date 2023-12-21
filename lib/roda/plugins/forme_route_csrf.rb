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
            token = if use_request_specific_token = opts.fetch(:use_request_specific_token){use_request_specific_csrf_tokens?}
              csrf_token(csrf_path(attr[:action]), method)
            else
              csrf_token
            end

            opts[:csrf] = [csrf_field, token]
            opts[:_before] = lambda do |form|
              form.tag(:input, :type=>:hidden, :name=>csrf_field, :value=>token)
            end

            if use_request_specific_token && (formaction_field = csrf_options[:formaction_field])
              formactions = opts[:formactions] = []
              formaction_tokens = opts[:formaction_tokens] = {}
              _after = opts[:_after]
              opts[:formaction_csrfs] = [formaction_field, formaction_tokens]
              formaction_field = csrf_options[:formaction_field]
              opts[:_after] = lambda do |form|
                formactions.each do |action, method|
                  path = csrf_path(action)
                  fa_token = csrf_token(path, method)
                  formaction_tokens[path] = fa_token
                  form.tag(:input, :type=>:hidden, :name=>"#{formaction_field}[#{path}]", :value=>fa_token)
                end
                _after.call(form) if _after
              end
            end
          end
        end
      end
    end

    register_plugin(:forme_route_csrf, FormeRouteCsrf)
  end
end
