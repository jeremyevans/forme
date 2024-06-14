# frozen-string-literal: true

require_relative '../../forme/template'

class Roda
  module RodaPlugins
    module FormeErubiCaptureBlock
      def self.load_dependencies(app)
        app.plugin :forme_route_csrf
      end

      class Form < ::Forme::Template::Form
        %w'inputs tag subform'.each do |meth|
          class_eval(<<-END, __FILE__, __LINE__+1)
            def #{meth}(*)
              if block_given?
                @scope.instance_variable_get(@scope.render_opts[:template_opts][:outvar]).capture{super}
              else
                super
              end
            end
          END
        end
      end

      module InstanceMethods
        def _forme_form(obj, attr, opts, &block)
          if block && opts[:emit] != false
            instance_variable_get(render_opts[:template_opts][:outvar]).capture{super}
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

    register_plugin(:forme_erubi_capture_block, FormeErubiCaptureBlock)
  end
end
