# frozen-string-literal: true

require_relative 'template'

class ActiveSupport::SafeBuffer
  include Forme::Raw
end

module Forme
  module Rails
    class TemplateForm < ::Forme::Template::Form
      %w'inputs tag subform'.each do |meth|
        class_eval(<<-END, __FILE__, __LINE__+1)
          def #{meth}(*)
            if block_given?
              @scope.send(:with_output_buffer){super}
            else
              @scope.raw(super)
            end
          end
        END
      end

      %w'button input'.each do |meth|
        class_eval(<<-END, __FILE__, __LINE__+1)
          def #{meth}(*)
            @scope.raw(super)
          end
        END
      end

      def emit(tag)
        @scope.output_buffer << @scope.raw(tag)
      end
    end

    ERB = Template::Helper.clone
    module ERB
      alias _forme form
      remove_method :form

      def forme(*a, &block)
        if block_given?
          with_output_buffer{_forme(*a, &block)}
        else
          raw(_forme(*a, &block))
        end
      end

      private

      remove_method :_forme_form_options
      def _forme_form_options(obj, attr, opts)
        if protect_against_forgery?
          opts[:_before_post] = lambda do |form|
            form.tag(:input, :type=>:hidden, :name=>request_forgery_protection_token, :value=>form_authenticity_token)
          end
        end
      end

      remove_method :_forme_form_class
      # The class to use for forms
      def _forme_form_class
        TemplateForm
      end
    end
  end
end
