# frozen-string-literal: true

module Sequel # :nodoc:
  module Plugins # :nodoc:
    # The forme_set plugin makes the model instance keep track of which form
    # inputs have been added for it, and adds a forme_set method to handle
    # the intake of submitted data from the form.
    module FormeSet
      SKIP_FORMATTERS = [:disabled, :readonly, ::Forme::Formatter::Disabled, ::Forme::Formatter::ReadOnly]

      def self.apply(model)
        model.plugin :forme
        model.plugin :instance_hooks
      end

      module InstanceMethods
        def forme_inputs
          @forme_inputs ||= {}
        end

        def forme_input(_form, field, _opts)
          forme_inputs[field] = super
        end

        def forme_set(params)
          forme_inputs.each do |field, input|
            opts = input.opts
            next if SKIP_FORMATTERS.include?(opts.fetch(:formatter){input.form.opts[:formatter]})

            if attr = opts[:attr]
              name = attr[:name] || attr['name']
            end
            name ||= opts[:name] || opts[:key] || next

            # Pull out last component of the name if there is one
            column = (name =~ /\[([^\[\]]+)\]\z/ ? $1 : name).to_sym

            send(:"#{column}=", params[column] || params[column.to_s])

            next unless ref = model.association_reflection(field)
            next unless options = opts[:options]

            values = options.map do |obj|
              case obj
              when Sequel::Model
                obj.pk
              when Array
                obj.last
              else
                obj
              end
            end

            after_validation_hook do
              value = send(column)

              valid = if ref[:type] == :many_to_one
                values.include?(value) || (value.nil? && opts[:add_blank])
              else
                (value - values).empty?
              end

              unless valid
                errors.add(column, 'invalid value submitted')
              end
            end
          end
        end
      end
    end
  end
end
