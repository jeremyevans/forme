# frozen-string-literal: true

require 'rack/utils'
require_relative '../../forme/template'

class Roda
  module RodaPlugins
    module FormeSet
      # Require the forme_route_csrf plugin.
      def self.load_dependencies(app, _ = nil)
        app.plugin :forme_route_csrf 
      end

      # Set the HMAC secret.
      def self.configure(app, opts = OPTS, &block)
        unless app.opts[:forme_set_hmac_secret] = opts[:secret] || app.opts[:forme_set_hmac_secret]
          raise RodaError, "must provide :secret option to forme_set plugin"
        end

        if block
          app.send(:define_method, :_forme_set_handle_error, &block)
          app.send(:private, :_forme_set_handle_error)
        end
      end

      # Error class raised for invalid form submissions.
      class Error < StandardError
      end

      # Map of error types to error messages
      ERROR_MESSAGES = {
        :missing_data=>"_forme_set_data parameter not submitted, make sure the forme_set Sequel plugin is loaded",
        :missing_hmac=>"_forme_set_data_hmac parameter not submitted, make sure the forme_set Sequel plugin is loaded",
        :hmac_mismatch=>"_forme_set_data_hmac does not match _forme_set_data",
        :csrf_mismatch=>"_forme_set_data CSRF token does not match submitted CSRF token",
        :missing_namespace=>"no content in expected namespace"
      }.freeze

      module InstanceMethods
        # Return hash based on submitted parameters, with :values key
        # being submitted values for the object, and :validations key
        # being a hash of validation metadata for the object.
        def forme_parse(obj)
          h = _forme_parse(obj)
          
          params = h.delete(:params)
          columns = h.delete(:columns)
          h[:validations] ||= {}

          values = h[:values] = {}
          columns.each do |col|
            values[col.to_sym] = params[col]
          end

          h
        end

        # Set fields on the object based on submitted parameters, as
        # well as validations for associated object values.
        def forme_set(obj)
          h = _forme_parse(obj)

          obj.set_fields(h[:params], h[:columns])

          if h[:validations]
            obj.forme_validations.merge!(h[:validations])
          end

          if block_given?
            yield h[:form_version], obj
          end

          obj
        end

        private

        # Raise error with message based on type
        def _forme_set_handle_error(type, _obj)
        end

        # Raise error with message based on type
        def _forme_parse_error(type, obj)
          _forme_set_handle_error(type, obj)
          raise Error, ERROR_MESSAGES[type]
        end

        # Include a reference to the current scope to the form.  This reference is needed
        # to correctly construct the HMAC.
        def _forme_form_options(obj, attr, opts)
          super

          opts[:_after] = lambda do |form|
            if (obj = form.opts[:obj]) && obj.respond_to?(:forme_inputs) && (forme_inputs = obj.forme_inputs)
              columns = []
              valid_values = {}

              forme_inputs.each do |field, input|
                next unless col = obj.send(:forme_column_for_input, input)
                col = col.to_s
                columns << col

                next unless validation = obj.send(:forme_validation_for_input, field, input)
                validation[0] = validation[0].to_s
                has_nil = false
                validation[1] = validation[1].map do |v|
                  has_nil ||= v.nil?
                  v.to_s
                end
                validation[1] << nil if has_nil
                valid_values[col] = validation
              end

              return if columns.empty?

              data = {}
              data['columns'] = columns
              data['namespaces'] = form.opts[:namespace]
              data['csrf'] = form.opts[:csrf]
              data['valid_values'] = valid_values unless valid_values.empty?
              data['form_version'] = form.opts[:form_version] if form.opts[:form_version]

              data = data.to_json
              form.tag(:input, :type=>:hidden, :name=>:_forme_set_data, :value=>data)
              form.tag(:input, :type=>:hidden, :name=>:_forme_set_data_hmac, :value=>OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA512.new, self.class.opts[:forme_set_hmac_secret], data))
            end
          end
        end

        # Internals of forme_parse_hmac and forme_set_hmac.
        def _forme_parse(obj)
          params = request.params
          return _forme_parse_error(:missing_data, obj) unless data = params['_forme_set_data']
          return _forme_parse_error(:missing_hmac, obj) unless hmac = params['_forme_set_data_hmac']

          data = data.to_s
          hmac = hmac.to_s
          actual = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA512.new, self.class.opts[:forme_set_hmac_secret], data)
          unless Rack::Utils.secure_compare(hmac.ljust(64), actual) && hmac.length == actual.length
            return _forme_parse_error(:hmac_mismatch, obj)
          end

          data = JSON.parse(data)
          csrf_field, hmac_csrf_value = data['csrf']
          if csrf_field
            csrf_value = params[csrf_field].to_s
            hmac_csrf_value = hmac_csrf_value.to_s
            unless Rack::Utils.secure_compare(csrf_value.ljust(hmac_csrf_value.length), hmac_csrf_value) && csrf_value.length == hmac_csrf_value.length
              return _forme_parse_error(:csrf_mismatch, obj)
            end
          end

          namespaces = data['namespaces']
          namespaces.each do |key|
            return _forme_parse_error(:missing_namespace, obj) unless params = params[key]
          end

          if valid_values = data['valid_values']
            validations = {}
            valid_values.each do |col, (type, values)|
              value = params[col]
              valid = if type == "subset"
                !value || (value - values).empty?
              else # type == "include"
                values.include?(value)
              end

              validations[col.to_sym] = [:valid, valid]
            end
          end

          {:params=>params, :columns=>data["columns"], :validations=>validations, :form_version=>data['form_version']}
        end
      end
    end

    register_plugin(:forme_set, FormeSet)
  end
end
