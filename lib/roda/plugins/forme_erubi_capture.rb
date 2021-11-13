# frozen-string-literal: true

require_relative '../../forme'

class Roda
  module RodaPlugins
    module FormeErubiCapture
      def self.load_dependencies(app)
        app.plugin :forme_route_csrf
        app.plugin :capture_erb
        app.plugin :inject_erb
      end

    # Subclass used when handling +form+ inside templates
    # using this plugin.  Based on the Rails integration, since
    # that has similar needs.
    class Form < ::Forme::Form
      def self.form(obj=nil, attr={}, opts={}, &block)
        if block
          super
        else
          # If no block is provided, don't need to use all of the
          # capturing/emitting provided by this class, so fallback
          # to using the ::Forme::Form
          ::Forme::Form.form(obj, attr, opts, &block)
        end
      end

      def initialize(*)
        super
        @scope = @opts[:scope]
      end

      def emit(tag)
        @scope.inject_erb(tag.to_s)
      end

      def inputs(*)
        if block_given?
          super
        else
          capture{super}
        end
      end
      
      def _inputs(inputs=[], opts={}) # :nodoc:
        if block_given?
          super 
        else
          emit(super)
        end
      end

      def tag(type, attr={}, children=[], &block)
        if block
          capture{tag_(type, attr, children, &block)}
        else
          _tag(type, attr, children).to_s
        end
      end
      
      def tag_(type, attr={}, children=[]) # :nodoc:
        tag = _tag(type, attr, children)
        emit(serialize_open(tag))
        Array(tag.children).each{|c| emit(c)}
        yield self if block_given?
        emit(serialize_close(tag))
      end

      private

      # Ignore argument for compatibility with ERBSequelForm.
      def capture(_=nil, &block)
        @scope.capture_erb(&block)
      end

      def subform_emit_contents_for_block?
        true
      end
    end

      module InstanceMethods
        private

        def _forme_form_class
          Form
        end

        def _forme_form_options(options)
          options[:scope] = self
          options
        end
      end
    end

    register_plugin(:forme_erubi_capture, FormeErubiCapture)
  end
end
