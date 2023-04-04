# frozen-string-literal: true

require_relative '../../forme'

module Sequel # :nodoc:
  module Plugins # :nodoc:
    # The forme_set plugin makes the model instance keep track of which form
    # inputs have been added for it. It adds a <tt>forme_set(params['model_name'])</tt> method to handle
    # the intake of submitted data from the form.  For more complete control,
    # it also adds a forme_parse method that returns a hash of information that can be
    # used to modify and validate the object.
    module FormeSet
      SKIP_FORMATTERS = [:disabled, :readonly, ::Forme::Formatter::Disabled, ::Forme::Formatter::ReadOnly]

      # Depend on the forme plugin, as forme_input already needs to be defined.
      def self.apply(model)
        model.plugin :forme
      end

      module InstanceMethods
        # Hash with column name symbol keys and Forme::SequelInput values
        def forme_inputs
          return (@forme_inputs || {}) if frozen?
          @forme_inputs ||= {}
        end

        # Temporarily reset forme_inputs to the empty hash before yielding to the block.  
        # Used by the Roda forme_set plugin to make sure each form only includes metadata
        # for inputs in that form, and not metadata for inputs for earlier forms on the same page.
        def isolate_forme_inputs
          return yield if frozen?

          forme_inputs = self.forme_inputs
          begin
            @forme_inputs = {}
            yield
          ensure
            @forme_inputs = forme_inputs.merge(@forme_inputs)
          end
        end

        # Hash with column name symbol keys and <tt>[subset, allowed_values]</tt> values.  +subset+
        # is a boolean flag, if true, the uploaded values should be a subset of the allowed values,
        # otherwise, there should be a single uploaded value that is a member of the allowed values.
        def forme_validations
          return (@forme_validations || {}) if frozen?
          @forme_validations ||= {}
        end

        # Keep track of the inputs used.
        def forme_input(_form, field, _opts)
          frozen? ? super : (forme_inputs[field] = super)
        end

        # Given the hash of submitted parameters, return a hash containing information on how to
        # set values in the model based on the inputs used on the related form.  Currently, the
        # hash contains the following information:
        # :values :: A hash of values that can be used to update the model, suitable for passing
        #            to Sequel::Model#set.
        # :validations :: A hash of values suitable for merging into forme_validations. Used to
        #                 check that the submitted values for associated objects match one of the
        #                 options for the input in the form.
        def forme_parse(params)
          hash = {}
          hash_values = hash[:values] = {}
          validations = hash[:validations] = {}

          forme_inputs.each do |field, input|
            next unless column = forme_column_for_input(input)
            hash_values[column] = params[column] || params[column.to_s]

            next unless validation = forme_validation_for_input(field, input)
            validations[column] = validation
          end

          hash
        end

        # Set the values in the object based on the parameters parsed from the form, and add
        # validations based on the form to ensure that associated objects match form values.
        def forme_set(params)
          hash = forme_parse(params)
          set(hash[:values])
          unless hash[:validations].empty?
            forme_validations.merge!(hash[:validations])
          end
          nil
        end

        # Check associated values to ensure they match one of options in the form.
        def validate
          super

          if validations = @forme_validations
            validations.each do |column, (type, values)|
              value = send(column)

              valid = case type
              when :subset
                # Handle missing value the same as the empty array,
                # can happen with PostgreSQL array associations 
                !value || (value - values).empty?
              when :include
                values.include?(value)
              when :valid
                values
              else
                raise Forme::Error, "invalid type used in forme_validations"
              end

              unless valid
                errors.add(column, 'invalid value submitted')
              end
            end
          end
        end

        private

        # Return the model column name to use for the given form input.
        def forme_column_for_input(input)
          opts = input.opts
          return if SKIP_FORMATTERS.include?(opts.fetch(:formatter){input.form_opts[:formatter]})

          attr = opts[:attr] || {}
          return unless name ||= attr[:name] || attr['name'] || opts[:name] || opts[:key]

          # Pull out last component of the name if there is one
          column = name.to_s.chomp('[]')
          if column =~ /\[([^\[\]]+)\]\z/
            $1
          else
            column
          end.to_sym
        end

        # Return the validation metadata to use for the given field name and form input.
        def forme_validation_for_input(field, input)
          return unless ref = model.association_reflection(field)
          opts = input.opts
          return unless options = opts[:options]

          values = if opts[:text_method]
            value_method = opts[:value_method] || opts[:text_method]
            options.map(&value_method)
          else
            options.map{|obj| obj.is_a?(Array) ? obj.last : obj}
          end

          if ref[:type] == :many_to_one && !opts[:required]
            values << nil
          end
          [ref[:type] != :many_to_one ? :subset : :include, values]
        end
      end
    end
  end
end
