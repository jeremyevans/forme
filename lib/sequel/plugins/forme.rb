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

      module SequelForm
        attr_accessor :nested_associations
        attr_accessor :namespaces

        def subform(association)
          nested_obj = obj.send(association)
          ref = obj.class.association_reflection(association)
          multiple = ref.returns_array?
          i = -1
          Array(nested_obj).each do |no|
            begin
              nested_associations << obj
              namespaces << "#{association}_attributes"
              namespaces << (i+=1) if multiple
              @obj = no
              emit(input(ref.associated_class.primary_key, :type=>:hidden, :label=>nil)) unless no.new?
              yield
            ensure
              @obj = nested_associations.pop
              namespaces.pop if multiple
              namespaces.pop
            end
          end
        end

        def namespaced_id(field)
          "#{namespaces.join('_')}_#{field}"
        end

        def namespaced_name(field, multiple=false)
          root, *nsps = namespaces
          "#{root}#{nsps.map{|n| "[#{n}]"}.join}[#{field}]#{'[]' if multiple}"
        end
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

        # The form related to this input field.
        attr_reader :form

        # The field/column name related to this input.  The type of
        # input created usually depends upon this field.
        attr_reader :field

        # The options hash related to this input.
        attr_reader :opts

        # The namespace used for the input, generally the underscored
        # name of +obj+'s class.  
        attr_reader :namespace

        # Set the +obj+, +field+, and +opts+ attributes.
        def initialize(obj, form, field, opts)
          @obj, @form, @field, @opts = obj, form, field, opts
        end

        def _input(*a)
          form._input(*a)
        end

        # Determine which type of input to used based on the given field.
        # If the field is a column, use the column's type to determine
        # an appropriate field type. If the field is an association,
        # use either a regular or multiple select input.  If it's not a
        # column or association, but the object responds to the method,
        # create a text input.  Otherwise, raise an +Error+.
        def input
          opts[:label] = humanize(field) unless opts.has_key?(:label)
          if sch = obj.db_schema[field] 
            handle_errors(field)
            meth = :"input_#{sch[:type]}"
            opts[:id] = form.namespaced_id(field) unless opts.has_key?(:id)
            opts[:name] = form.namespaced_name(field) unless opts.has_key?(:name)
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
            opts[:id] = form.namespaced_id(field) unless opts.has_key?(:id)
            opts[:name] = form.namespaced_name(field) unless opts.has_key?(:name)
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
          opts[:name] = form.namespaced_name(key) unless opts.has_key?(:name)
          opts[:value] = obj.send(key) unless opts.has_key?(:value)
          opts[:options] = association_select_options(ref) unless opts.has_key?(:options)
          if opts.delete(:type) == :radio
            label = opts.delete(:label)
            val = opts.delete(:value)
            radios = opts.delete(:options).map{|l, pk| _input(:radio, opts.merge(:value=>pk, :label=>l, :checked=>(pk == val)))}
            radios.unshift("#{label}: ")
            radios
          else
            opts[:id] = form.namespaced_id(key) unless opts.has_key?(:id)
            opts[:add_blank] = true if !opts.has_key?(:add_blank) && (sch = obj.model.db_schema[key])  && sch[:allow_null]
            _input(:select, opts)
          end
        end

        # Create a multiple select input made up of options for all entries the object
        # could be associated to, with all of the ones currently associated to being selected.
        def association_one_to_many(ref)
          key = ref[:key]
          klass = ref.associated_class
          pk = klass.primary_key
          field = "#{klass.send(:singularize, ref[:name])}_pks"
          opts[:name] = form.namespaced_name(field, :multiple) unless opts.has_key?(:name)
          opts[:value] = obj.send(ref[:name]).map{|x| x.send(pk)} unless opts.has_key?(:value)
          opts[:options] = association_select_options(ref) unless opts.has_key?(:options)
          if opts.delete(:type) == :checkbox
            label = opts.delete(:label)
            val = opts.delete(:value)
            cbs = opts.delete(:options).map{|l, pk| _input(:checkbox, opts.merge(:value=>pk, :label=>l, :checked=>val.include?(pk), :no_hidden=>true))}
            cbs.unshift("#{label}: ")
            cbs
          else
            opts[:id] = form.namespaced_id(field) unless opts.has_key?(:id)
            opts[:multiple] = true
            _input(:select, opts)
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
            _input(:select, opts)
          else
            opts[:checked] = obj.send(field)
            opts[:value] = 't'
            _input(:checkbox, opts)
          end
        end

        # Fallback to using the text type for all other types of input.
        def input_other(sch)
          opts[:value] = obj.send(field) unless opts.has_key?(:value)
          type = opts.delete(:type) || :text
          _input(type, opts)
        end

        # 
        def input_date(sch)
          if !opts.has_key?(:value) && (v = obj.send(field))
            opts[:value] = v.strftime('%m/%d/%Y')
          end
          type = opts.delete(:type) || :text
          _input(type, opts)
        end
      end

      module InstanceMethods
        def forme_config(form)
          form.extend(SequelForm)
          form.nested_associations = []
          form.namespaces = [model.send(:underscore, model.name)]
        end

        # Return <tt>Forme::Input</tt> instance for field and opts.
        def forme_input(form, field, opts)
          SequelInput.new(self, form, field, opts).input
        end
      end
    end
  end
end
