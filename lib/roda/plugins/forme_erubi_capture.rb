# frozen-string-literal: true

require_relative '../../forme/template'

class Roda
  module RodaPlugins
    module FormeErubiCapture
      def self.load_dependencies(app)
        app.plugin :forme_route_csrf
        app.plugin :capture_erb
        app.plugin :inject_erb
      end

      class Form < ::Forme::Template::Form
        %w'inputs tag subform'.each do |meth|
          class_eval(<<-END, __FILE__, __LINE__+1)
            def #{meth}(*)
              if block_given? && @form.opts[:emit] != false
                @scope.capture_erb do
                  super
                  @scope.instance_variable_get(@scope.render_opts[:template_opts][:outvar])
                end
              else
                super
              end
            end
          END
        end
        
        def emit(tag)
          @scope.inject_erb(tag)
        end
      end

      module InstanceMethods
        def form(obj=nil, attr={}, opts={}, &block)
          if block && (obj.is_a?(Hash) ? attr : opts)[:emit] != false
            capture_erb do
              super
              instance_variable_get(render_opts[:template_opts][:outvar])
            end
          else
            super
          end
        end

        private

        def _forme_form_class
          Form
        end
      end
    end

    register_plugin(:forme_erubi_capture, FormeErubiCapture)
  end
end
