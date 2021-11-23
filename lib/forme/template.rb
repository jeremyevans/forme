# frozen-string-literal: true

require_relative '../forme'

module Forme
  module Template
    class Form
      def initialize(form, scope)
        @form = form
        @scope = scope
      end

      # Delegate calls by default to the wrapped form
      def method_missing(*a, &block)
        @form.public_send(*a, &block)
      end

      # If a block is given to inputs, tag, or subform, 
      # emit the already generated HTML for the form before yielding
      # to the block, and after returning, emit any HTML generated
      # after returning from the block.
      %w'inputs tag subform'.each do |meth|
        class_eval(<<-END, __FILE__, __LINE__+1)
          def #{meth}(*a, &block)
            return @form.#{meth}(*a) unless block

            buffer = @form.to_s
            offset = buffer.length
            @form.#{meth}(*a) do
              emit(buffer[offset, buffer.length])
              yield self
              offset = buffer.length
            end
            emit(buffer[offset, buffer.length])

            nil
          end
        END
      end

      # Serialize the tag and inject it into the output.
      def emit(tag)
        return unless output = output()
        output << tag
      end

      private

      def output
        @scope.instance_variable_get(:@_out_buf)
      end
    end

    # This is the module used to add the Forme integration
    # to ERB.
    module Helper 
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

        _forme_form_options(obj, attribs, options)
        _forme_form(obj, attr, opts, &block)
      end

      private

      def _forme_form(obj, attr, opts, &block)
        if block_given?
          erb_form = buffer = offset = nil
          block = proc do
            wrapped_form = erb_form.instance_variable_get(:@form)
            buffer = wrapped_form.to_s
            offset = buffer.length
            erb_form.emit(buffer[0, buffer.length])
            yield erb_form
            offset = buffer.length
          end

          f, attr, block = _forme_wrapped_form_class.form_args(obj, attr, opts, &block)
          erb_form = _forme_form_class.new(f, self)
          erb_form.form(attr, &block)
          erb_form.emit(buffer[offset, buffer.length])
        else
          _forme_wrapped_form_class.form(obj, attr, opts, &block)
        end
      end

      def _forme_wrapped_form_class
        ::Forme::Form
      end

      # The class to use for forms
      def _forme_form_class
        Form
      end

      # The options to use for forms.  Any changes should mutate this hash to set options.
      def _forme_form_options(obj, attr, opts)
        if hidden_tags = _forme_form_hidden_tags
          opts[:hidden_tags] ||= []
          opts[:hidden_tags] += hidden_tags
        end
      end

      def _forme_form_hidden_tags
        nil
      end
    end 
  end
end
