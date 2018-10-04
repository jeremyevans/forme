# frozen-string-literal: true

module Sequel # :nodoc:
  module Plugins # :nodoc:
    # The forme_set plugin makes the model instance keep track of which form
    # inputs have been added for it. It adds a forme_set method to handle
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
          @forme_inputs ||= {}
        end

        # Hash with column name symbol keys and <tt>[subset, allowed_values]</tt> values.  +subset+
        # is a boolean flag, if true, the uploaded values should be a subset of the allowed values,
        # otherwise, there should be a single uploaded value that is a member of the allowed values.
        def forme_validations
          @forme_validations ||= {}
        end

        # Keep track of the inputs used.
        def forme_input(_form, field, _opts)
          forme_inputs[field] = super
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
            opts = input.opts
            next if SKIP_FORMATTERS.include?(opts.fetch(:formatter){input.form_opts[:formatter]})

            if attr = opts[:attr]
              name = attr[:name] || attr['name']
            end
            name ||= opts[:name] || opts[:key] || next

            # Pull out last component of the name if there is one
            column = (name =~ /\[([^\[\]]+)\]\z/ ? $1 : name)
            column = column.to_s.sub(/\[\]\z/, '').to_sym

            hash_values[column] = params[column] || params[column.to_s]

            next unless ref = model.association_reflection(field)
            next unless options = opts[:options]

            values = if opts[:text_method]
              value_method = opts[:value_method] || opts[:text_method]
              options.map(&value_method)
            else
              options.map{|obj| obj.is_a?(Array) ? obj.last : obj}
            end

            if ref[:type] == :many_to_one && !opts[:required]
              values << nil
            end
            validations[column] = [ref[:type] != :many_to_one ? :subset : :include, values]
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
              else
                raise Forme::Error, "invalid type used in forme_validations"
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
