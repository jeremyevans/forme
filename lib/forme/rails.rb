# frozen-string-literal: true

require_relative 'template'

class ActiveSupport::SafeBuffer
  include Forme::Raw
end

module Forme
  module Rails
    HIDDEN_TAGS = []

    # Add a hidden tag proc that will be used for all forms created via Forme::Rails::ERB#form.
    # The block is yielded the Forme::Tag object for the form tag.
    # The block should return either nil if hidden tag should be added, or a Forme::Tag object (or an array of them),
    # or a hash with keys specifying the name of the tags and the values specifying the values of the tags .
    def self.add_hidden_tag(&block)
      HIDDEN_TAGS << block
    end

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

      def _forme_form_options(obj, attr, opts)
        opts[:_before] = lambda do |form|
          if protect_against_forgery? && (form.form_tag_attributes[:method] || form.form_tag_attributes['method']).to_s.upcase == 'POST'
            form.tag(:input, :type=>:hidden, :name=>request_forgery_protection_token, :value=>form_authenticity_token)
          end
        end
      end

      # The class to use for forms
      def _forme_form_class
        TemplateForm
      end

      def _forme_form_hidden_tags
        Forme::Rails::HIDDEN_TAGS
      end
    end
  end
end
