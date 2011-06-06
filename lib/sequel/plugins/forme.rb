require 'forme'

module Sequel # :nodoc:
  module Plugins # :nodoc:
    # This Sequel plugin allows easy use of Forme with Sequel.
    module Forme
      # Exception class raised by the plugin.  It's important to
      # note this descends from <tt>Forme::Error</tt> and not
      # <tt>Sequel::Error</tt>, though in practice it's unlikely
      # you will want to rescue these errors.
      class Error < ::Forme::Error
      end

      # Helper class for dealing with Forme/Sequel integration.
      # One instance is created for each call to <tt>Forme::Form#input</tt>
      # for forms associated with <tt>Sequel::Model</tt> objects.
      class SequelInput
        include ::Forme

        # The name methods that will be tried, in order, to get the
        # text to use for the options in the select input created
        # for associations.
        FORME_NAME_METHODS = [:forme_name, :name, :title, :number]

        # The <tt>Sequel::Model</tt> object related to this input.
        attr_reader :obj

        # The field/column name related to this input.  The type of
        # input created usually depends upon this field.
        attr_reader :field

        # The options hash related to this input.
        attr_reader :opts

        # The namespace used for the input, generally the underscored
        # name of +obj+'s class.  
        attr_reader :namespace

        # Set the +obj+, +field+, and +opts+ attributes.
        def initialize(obj, field, opts)
          @obj, @field, @opts = obj, field, opts
          @namespace ||= obj.model.send(:underscore, obj.model.name)
        end

        # Determine which type of input to used based on the given field.
        # If the field is a column, use the column's type to determine
        # an appropriate field type. If the field is an association,
        # use either a regular or multiple select input.  If it's not a
        # column or association, but the object responds to the method,
        # create a text input.  Otherwise, raise an +Error+.
        def input
          opts[:label] ||= humanize(field)
          if sch = obj.db_schema[field] 
            handle_errors(field)
            meth = :"input_#{sch[:type]}"
            opts[:id] ||= "#{namespace}_#{field}"
            opts[:name] ||= "#{namespace}[#{field}]"
            opts[:required] = true if !opts.has_key?(:required) && sch[:allow_null] == false
            if respond_to?(meth, true)
              send(meth, sch)
            else
              input_other(sch)
            end
          elsif ref = obj.model.association_reflection(field)
            meth = :"association_#{ref[:type]}"
            if respond_to?(meth, true)
              send(meth, ref)
            else
              raise Error, "Association type #{ref[:type]} not currently handled for association #{ref[:name]}"
            end
          elsif obj.respond_to?(field)
            opts[:id] ||= "#{namespace}_#{field}"
            opts[:name] ||= "#{namespace}[#{field}]"
            input_other({})
          else
            raise Error, "Unrecognized field used: #{field}"
          end
        end

        private

        # Set the error option correctly if the field contains errors
        def handle_errors(f)
          if e = obj.errors.on(f)
            opts[:error] = e.join(', ')
          end
        end

        # If the :name_method option is provided, use that as the method.
        # Otherwise, pick the first method in +FORME_NAME_METHODS+ that
        # the associated class implements and use it.  If none of the
        # methods are implemented by the associated class, raise an +Error+.
        def forme_name_method(ref)
          if meth = opts.delete(:name_method)
            meth
          else
            meths = FORME_NAME_METHODS & ref.associated_class.instance_methods.map{|s| s.to_sym}
            if meths.empty?
              raise Error, "No suitable name method found for association #{ref[:name]}"
            else
              meths.first
            end
          end
        end

        # Create a regular select input made up of options for all entries the object
        # could be associated to, with the one currently associated to being selected.
        def association_many_to_one(ref)
          key = ref[:key]
          handle_errors(key)
          opts[:name] ||= "#{namespace}[#{key}]"
          opts[:value] ||= obj.send(key)
          opts[:options] ||= association_select_options(ref)
          if opts.delete(:type) == :radio
            label = opts.delete(:label)
            val = opts.delete(:value)
            radios = opts.delete(:options).map{|l, pk| Input.new(:radio, opts.merge(:value=>pk, :label=>l, :checked=>(pk == val)))}
            radios.unshift("#{label}: ")
            radios
          else
            opts[:id] ||= "#{namespace}_#{key}"
            opts[:add_blank] = true if !opts.has_key?(:add_blank) && (sch = obj.model.db_schema[key])  && sch[:allow_null]
            Input.new(:select, opts)
          end
        end

        # Create a multiple select input made up of options for all entries the object
        # could be associated to, with all of the ones currently associated to being selected.
        def association_one_to_many(ref)
          key = ref[:key]
          klass = ref.associated_class
          pk = klass.primary_key
          opts[:name] ||= "#{namespace}[#{klass.send(:singularize, ref[:name])}_pks][]"
          opts[:value] ||= obj.send(ref[:name]).map{|x| x.send(pk)}
          opts[:options] ||= association_select_options(ref)
          if opts.delete(:type) == :checkbox
            label = opts.delete(:label)
            val = opts.delete(:value)
            cbs = opts.delete(:options).map{|l, pk| Input.new(:checkbox, opts.merge(:value=>pk, :label=>l, :checked=>val.include?(pk), :no_hidden=>true))}
            cbs.unshift("#{label}: ")
            cbs
          else
            opts[:id] ||= "#{namespace}_#{klass.send(:singularize, ref[:name])}_pks"
            opts[:multiple] = true
            Input.new(:select, opts)
          end
        end
        alias association_many_to_many association_one_to_many

        # Return an array of two element arrays represeneting the
        # select options that should be created.
        def association_select_options(ref)
          name_method = forme_name_method(ref)
          obj.send(:_apply_association_options, ref, ref.associated_class.dataset).unlimited.all.map{|a| [a.send(name_method), a.pk]}
        end

        # Call humanize on a string version of the argument if
        # String#humanize exists. Otherwise, do some monkeying
        # with the string manually.
        def humanize(s)
          s = s.to_s
          s.respond_to?(:humanize) ? s.humanize : s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
        end

        # If the column allows NULL values, use a three-valued select
        # input.  If not, use a simple checkbox.
        def input_boolean(sch)
          if !opts.delete(:required)
            v = opts[:value] || obj.send(field)
            opts[:value] = (v ? 't' : 'f') unless v.nil?
            opts[:add_blank] = true
            opts[:options] = [['True', 't'], ['False', 'f']]
            Input.new(:select, opts)
          else
            opts[:checked] = obj.send(field)
            opts[:value] = 't'
            Input.new(:checkbox, opts)
          end
        end

        # Fallback to using the text type for all other types of input.
        def input_other(sch)
          opts[:value] ||= obj.send(field)
          type = opts.delete(:type) || :text
          Input.new(type, opts)
        end

        # 
        def input_date(sch)
          opts[:value] ||= begin
            v = obj.send(field)
            v.strftime('%m/%d/%Y') if v
          end
          type = opts.delete(:type) || :text
          Input.new(type, opts)
        end
      end

      module InstanceMethods
        # Return <tt>Forme::Input</tt> instance for field and opts.
        def forme_input(field, opts)
          SequelInput.new(self, field, opts).input
        end
      end
    end
  end
end
