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

      # This module extends all <tt>Forme::Form</tt> instances
      # that use a <tt>Sequel::Model</tt> instance as the form's
      # +obj+.
      module SequelForm
        # Stack of objects used by subform.  The current +obj+
        # is added to the top of the stack on a call to +subform+,
        # the nested associated object is set as the current +obj+ during the
        # call to +subform+, and when +subform+ returns, the top of the
        # stack is set as the current +obj+.
        attr_accessor :nested_associations

        # The namespaces that should be added to the id and name
        # attributes for the receiver's inputs.  Used as a stack
        # by +subform+.
        attr_accessor :namespaces

        # Call humanize on a string version of the argument if
        # String#humanize exists. Otherwise, do some monkeying
        # with the string manually.
        def humanize(s)
          s = s.to_s
          s.respond_to?(:humanize) ? s.humanize : s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
        end

        # Handle nested association usage.  The +association+ should be a name
        # of the association for the form's +obj+. Inside the block, calls to
        # the +input+ and +inputs+ methods for the receiver treat the associated
        # object as the recevier's +obj+, using name and id attributes that work
        # with the Sequel +nested_attributes+ plugin.
        #
        # The following options are currently supported:
        # :inputs :: Automatically call +inputs+ with the given values.  Using
        #            this, it is not required to pass a block to the method,
        #            though it will still work if you do.
        # :legend :: If :inputs is also used, this is passed to it to override
        #            the default :legend used.  You can also use a proc as the value,
        #            which will called with each associated object (and the position
        #            in the associated object already for *_to_many associations),
        #            and should return the legend string to use for that object.
        def subform(association, opts={}, &block)
          nested_obj = obj.send(association)
          ref = obj.class.association_reflection(association)
          multiple = ref.returns_array?
          i = -1
          ins = opts[:inputs]
          Array(nested_obj).each do |no|
            begin
              nested_associations << obj
              namespaces << "#{association}_attributes"
              namespaces << (i+=1) if multiple
              @obj = no
              emit(input(ref.associated_class.primary_key, :type=>:hidden, :label=>nil)) unless no.new?
              if ins
                options = opts.dup
                if options.has_key?(:legend)
                  if options[:legend].respond_to?(:call)
                    options[:legend] = options[:legend].call(no, i)
                  end
                else
                  if multiple
                    options[:legend] = humanize("#{obj.model.send(:singularize, association)} ##{i+1}")
                  else
                    options[:legend] = humanize(association)
                  end
                end
                inputs(ins, options, &block)  
              else
                yield
              end
            ensure
              @obj = nested_associations.pop
              namespaces.pop if multiple
              namespaces.pop
            end
          end
          nil
        end

        # Return a unique id attribute for the +field+, handling
        # nested attributes use.
        def namespaced_id(field)
          "#{namespaces.join('_')}_#{field}"
        end

        # Return a unique name attribute for the +field+, handling nested
        # attribute use.  If +multiple+ is true, end the name
        # with [] so that param parsing will treat the name as part of an array.
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

        # The <tt>Sequel::Model</tt> object related to the receiver.
        attr_reader :obj

        # The form related to the receiver.
        attr_reader :form

        # The field/column name related to the receiver.  The type of
        # input created usually depends upon this field.
        attr_reader :field

        # The options hash related to the receiver.
        attr_reader :opts

        # Set the +obj+, +form+, +field+, and +opts+ attributes.
        def initialize(obj, form, field, opts)
          @obj, @form, @field, @opts = obj, form, field, opts
        end

        # Determine which type of input to used based on the +field+.
        # If the field is a column, use the column's type to determine
        # an appropriate field type. If the field is an association,
        # use either a regular or multiple select input (or multiple radios or
        # checkboxes if the related :type option is used).  If it's not a
        # column or association, but the object responds to +field+,
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

        # Create an +Input+ instance associated to the receiver's +form+
        # with the given arguments.
        def _input(*a)
          form._input(*a)
        end

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

        # Create a select input made up of options for all entries the object
        # could be associated to, with the one currently associated to being selected.
        # If the :type=>:radio option is used, use multiple radio buttons instead of
        # a select box.  For :type=>:radio, you can also provide a :tag_wrapper option
        # used to wrap the individual radio buttons.
        def association_many_to_one(ref)
          key = ref[:key]
          handle_errors(key)
          opts[:name] = form.namespaced_name(key) unless opts.has_key?(:name)
          opts[:value] = obj.send(key) unless opts.has_key?(:value)
          opts[:options] = association_select_options(ref) unless opts.has_key?(:options)
          if opts.delete(:type) == :radio
            label = opts.delete(:label)
            val = opts.delete(:value)
            tag_wrapper = opts.delete(:tag_wrapper) || :default
            wrapper = form.transformer(:wrapper, opts)
            opts.delete(:wrapper)
            radios = opts.delete(:options).map{|l, pk| _input(:radio, opts.merge(:value=>pk, :wrapper=>tag_wrapper, :label=>l, :checked=>(pk == val)))}
            radios.unshift("#{label}: ")
            wrapper ? wrapper.call(TagArray.new(form, radios)) : radios
          else
            opts[:id] = form.namespaced_id(key) unless opts.has_key?(:id)
            opts[:add_blank] = true if !opts.has_key?(:add_blank) && (sch = obj.model.db_schema[key])  && sch[:allow_null]
            _input(:select, opts)
          end
        end

        # Create a multiple select input made up of options for all entries the object
        # could be associated to, with all of the ones currently associated to being selected.
        # If the :type=>:checkbox option is used, use multiple checkboxes instead of
        # a multiple select box.  For :type=>:checkbox, you can also provide a :tag_wrapper option
        # used to wrap the individual checkboxes.
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
            tag_wrapper = opts.delete(:tag_wrapper) || :default
            wrapper = form.transformer(:wrapper, opts)
            opts.delete(:wrapper)
            cbs = opts.delete(:options).map{|l, pk| _input(:checkbox, opts.merge(:value=>pk, :wrapper=>tag_wrapper, :label=>l, :checked=>val.include?(pk), :no_hidden=>true))}
            cbs.unshift("#{label}: ")
            wrapper ? wrapper.call(TagArray.new(form, cbs)) : cbs
          else
            opts[:id] = form.namespaced_id(field) unless opts.has_key?(:id)
            opts[:multiple] = true
            _input(:select, opts)
          end
        end
        alias association_many_to_many association_one_to_many

        # Return an array of two element arrays representing the
        # select options that should be created.
        def association_select_options(ref)
          name_method = forme_name_method(ref)
          obj.send(:_apply_association_options, ref, ref.associated_class.dataset).unlimited.all.map{|a| [a.send(name_method), a.pk]}
        end

        # Delegate to the +form+.
        def humanize(s)
          form.humanize(s)
        end

        # If the column allows +NULL+ values, use a three-valued select
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

        # Format date values using US-style MM/DD/YYYY, though this will
        # change in the future.
        def input_date(sch)
          if !opts.has_key?(:value) && (v = obj.send(field))
            opts[:value] = v.strftime('%m/%d/%Y')
          end
          type = opts.delete(:type) || :text
          _input(type, opts)
        end
      end

      module InstanceMethods
        # Configure the +form+ with support for <tt>Sequel::Model</tt>
        # specific code, such as support for nested attributes.
        def forme_config(form)
          form.extend(SequelForm)
          form.nested_associations = []
          form.namespaces = [model.send(:underscore, model.name)]
        end

        # Return <tt>Forme::Input</tt> instance based on the given arguments.
        def forme_input(form, field, opts)
          SequelInput.new(self, form, field, opts).input
        end
      end
    end
  end
end
