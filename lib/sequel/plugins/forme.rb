require 'forme'
require 'thread'

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
        # Use the post method by default for Sequel forms, unless
        # overridden with the :method attribute.
        def form(attr={}, &block)
          attr = {:method=>:post}.merge(attr)
          attr[:class] = ::Forme.merge_classes(attr[:class], "forme", obj.model.send(:underscore, obj.model.name))
          super(attr, &block)
        end

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
        # :legend :: Overrides the default :legend used (which is based on the
        #            association name).  You can also use a proc as the value,
        #            which will called with each associated object (and the position
        #            in the associated object already for *_to_many associations),
        #            and should return the legend string to use for that object.
        # :grid :: Sets up a table with one row per associated object, and
        #          one column per field.
        # :labels :: When using the :grid option, override the labels that would
        #            be created via the :inputs option.  If you are not providing
        #            an :inputs option or are using a block with additional inputs,
        #            you should specify this option.
        # :skip_primary_key :: Skip adding a hidden primary key field for existing
        #                      objects.
        def subform(association, opts={}, &block)
          nested_obj = opts.has_key?(:obj) ? opts[:obj] : obj.send(association)
          ref = obj.class.association_reflection(association)
          multiple = ref.returns_array?
          grid = opts[:grid]
          ns = "#{association}_attributes"

          contents = proc do
            send(multiple ? :each_obj : :with_obj, nested_obj, ns) do |no, i|
              emit(input(ref.associated_class.primary_key, :type=>:hidden, :label=>nil, :wrapper=>nil)) unless no.new? || opts[:skip_primary_key]
              options = opts.dup
              if grid
                options.delete(:legend)
              else
                if options.has_key?(:legend)
                  if options[:legend].respond_to?(:call)
                    options[:legend] = multiple ? options[:legend].call(no, i) : options[:legend].call(no)
                  end
                else
                  if multiple
                    options[:legend] = humanize("#{obj.model.send(:singularize, association)} ##{i+1}")
                  else
                    options[:legend] = humanize(association)
                  end
                end
              end
              options[:subform] = true
              _inputs(options[:inputs]||[], options, &block)
            end
          end
          
          if grid
            labels = opts.fetch(:labels){opts[:inputs].map{|l, *| humanize(l)} if opts[:inputs]}
            legend = opts.fetch(:legend){humanize(association)}
            inputs_opts = opts[:inputs_opts] || {}
            inputs(inputs_opts.merge(:inputs_wrapper=>:table, :nested_inputs_wrapper=>:tr, :wrapper=>:td, :labeler=>nil, :labels=>labels, :legend=>legend), &contents)
          else
            contents.call
          end
          nil
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
        # checkboxes if the related :as option is used).  If it's not a
        # column or association, but the object responds to +field+,
        # create a text input.  Otherwise, raise an +Error+.
        def input
          opts[:attr] = opts[:attr] ? opts[:attr].dup : {}
          opts[:wrapper_attr] = opts[:wrapper_attr] ? opts[:wrapper_attr].dup : {}
          handle_errors(field)
          handle_validations(field)

          type = opts[:type]
          if !type && (sch = obj.db_schema[field])
            meth = :"input_#{sch[:type]}"
            opts[:key] = field unless opts.has_key?(:key)
            opts[:required] = true if !opts.has_key?(:required) && sch[:allow_null] == false && sch[:type] != :boolean
            handle_label(field)

            ::Forme.attr_classes(opts[:wrapper_attr], sch[:type])
            ::Forme.attr_classes(opts[:wrapper_attr], "required") if opts[:required]

            if respond_to?(meth, true)
              send(meth, sch)
            else
              input_other(sch)
            end
          elsif !type && (ref = obj.model.association_reflection(field))
            ::Forme.attr_classes(opts[:wrapper_attr], ref[:type])
            meth = :"association_#{ref[:type]}"
            if respond_to?(meth, true)
              send(meth, ref)
            else
              raise Error, "Association type #{ref[:type]} not currently handled for association #{ref[:name]}"
            end
          else
            rt = obj.respond_to?(field)
            raise(Error, "Unrecognized field used: #{field}") unless rt || type
            meth = :"input_#{type}"
            opts[:value] = nil unless rt || opts.has_key?(:value)
            opts[:key] = field unless opts.has_key?(:key)
            handle_label(field)
            if respond_to?(meth, true)
              opts.delete(:type)
              send(meth, opts)
            else
              input_other(opts)
            end
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

        # Set the label option appropriately, adding a * if the field
        # is required.
        def handle_label(f)
          opts[:label] = humanize(field) unless opts.has_key?(:label)
          opts[:label] = [opts[:label], form._tag(:abbr, {:title=>'required'}, '*')] if opts[:required]
        end

        # Update the attributes and options for any recognized validations
        def handle_validations(f)
          m = obj.model
          if m.respond_to?(:validation_reflections) and (vs = m.validation_reflections[f])
            attr = opts[:attr]
            vs.each do |type, options|
              attr[:placeholder] = options[:placeholder] if options[:placeholder] && !attr.has_key?(:placeholder)

              case type
              when :format
                attr[:pattern] = options[:with].source unless attr.has_key?(:pattern)
                attr[:title] = options[:title] unless attr.has_key?(:title)
              when :length
                unless attr.has_key?(:maxlength)
                  if max =(options[:maximum] || options[:is])
                    attr[:maxlength] = max
                  elsif (w = options[:within]) && w.is_a?(Range)
                    attr[:maxlength] = if w.exclude_end? && w.end.is_a?(Integer)
                      w.end - 1
                    else
                      w.end
                    end
                  end
                end
              when :numericality
                unless attr.has_key?(:pattern)
                  attr[:pattern] = if options[:only_integer]
                    "^[+\\-]?\\d+$"
                  else
                    "^[+\\-]?\\d+(\\.\\d+)?$"
                  end
                end
                attr[:title] = options[:title] || "must be a number" unless attr.has_key?(:title)
              end
            end
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
            meths = FORME_NAME_METHODS & ref.associated_class.instance_methods.map(&:to_sym)
            if meths.empty?
              raise Error, "No suitable name method found for association #{ref[:name]}"
            else
              meths.first
            end
          end
        end

        # Create a select input made up of options for all entries the object
        # could be associated to, with the one currently associated to being selected.
        # If the :as=>:radio option is used, use multiple radio buttons instead of
        # a select box.  For :as=>:radio, you can also provide a :tag_wrapper option
        # used to wrap the individual radio buttons.
        def association_many_to_one(ref)
          key = ref[:key]
          handle_errors(key)
          opts[:key] = key unless opts.has_key?(:key)
          opts[:value] = obj.send(key) unless opts.has_key?(:value)
          opts[:options] = association_select_options(ref) unless opts.has_key?(:options)
          if opts.delete(:as) == :radio
            handle_label(field)
            _input(:radioset, opts)
          else
            opts[:required] = true if !opts.has_key?(:required) && (sch = obj.model.db_schema[key]) && !sch[:allow_null]
            opts[:add_blank] = true if !opts.has_key?(:add_blank) && !(opts[:required] && opts[:value])
            handle_label(field)
            ::Forme.attr_classes(opts[:wrapper_attr], "required") if opts[:required]
            _input(:select, opts)
          end
        end

        # Create a multiple select input made up of options for all entries the object
        # could be associated to, with all of the ones currently associated to being selected.
        # If the :as=>:checkbox option is used, use multiple checkboxes instead of
        # a multiple select box.  For :as=>:checkbox, you can also provide a :tag_wrapper option
        # used to wrap the individual checkboxes.
        def association_one_to_many(ref)
          key = ref[:key]
          klass = ref.associated_class
          pk = klass.primary_key
          label = klass.send(:singularize, ref[:name])

          field = if ref[:type] == :pg_array_to_many
            handle_errors(key)
            key
          else
            "#{label}_pks"
          end

          unless opts.has_key?(:key)
            opts[:array] = true unless opts.has_key?(:array)
            opts[:key] = field
          end
          opts[:value] = obj.send(ref[:name]).map{|x| x.send(pk)} unless opts.has_key?(:value)
          opts[:options] = association_select_options(ref) unless opts.has_key?(:options)
          handle_label(label)
          if opts.delete(:as) == :checkbox
            _input(:checkboxset, opts)
          else
            opts[:multiple] = true unless opts.has_key?(:multiple)
            _input(:select, opts)
          end
        end
        alias association_many_to_many association_one_to_many
        alias association_pg_array_to_many association_one_to_many

        # Return an array of two element arrays representing the
        # select options that should be created.
        def association_select_options(ref)
          case ds = opts[:dataset]
          when nil
            ds = association_select_options_dataset(ref)
          when Proc, Method
            ds = ds.call(association_select_options_dataset(ref))
          end
          rows = ds.all

          case name_method = forme_name_method(ref)
          when Symbol, String
            rows.map{|a| [a.send(name_method), a.pk]}
          else
            rows.map{|a| [name_method.call(a), a.pk]}
          end
        end

        # The dataset to use to retrieve the association select options
        def association_select_options_dataset(ref)
          obj.send(:_apply_association_options, ref, ref.associated_class.dataset.clone).unlimited
        end

        # Delegate to the +form+.
        def humanize(s)
          form.humanize(s)
        end

        # If the column allows +NULL+ values, use a three-valued select
        # input.  If not, use a simple checkbox.  You can also use :as=>:select,
        # as :as=>:radio, or :as=>:checkbox to specify a particular style.
        def input_boolean(sch)
          unless opts.has_key?(:as)
            opts[:as] = (sch[:allow_null] || opts[:required] == false) ? :select : :checkbox
          end

          case opts[:as]
          when :radio
            v = opts.has_key?(:value) ? opts[:value] : obj.send(field)
            true_value = opts[:true_value]||'t'
            false_value = opts[:false_value]||'f'
            opts[:options] = [[opts[:true_label]||'Yes', {:value=>true_value, :key_id=>'yes'}], [opts[:false_label]||'No', {:value=>false_value, :key_id=>'no'}]]
            unless v.nil?
              opts[:value] = v ? true_value : false_value
            end
            _input(:radioset, opts)
          when :select
            v = opts[:value] || obj.send(field)
            opts[:value] = (v ? 't' : 'f') unless v.nil?
            opts[:add_blank] = true unless opts.has_key?(:add_blank)
            opts[:options] = [[opts[:true_label]||'True', opts[:true_value]||'t'], [opts[:false_label]||'False', opts[:false_value]||'f']]
            _input(:select, opts)
          else
            opts[:checked] = obj.send(field)
            opts[:value] = 't'
            _input(:checkbox, opts)
          end
        end

        # Use a file type for blobs.
        def input_blob(sch)
          opts[:value] = nil
          standard_input(:file)
        end

        # Use the text type by default for other cases not handled.
        def input_string(sch)
          if opts[:as] == :textarea
            standard_input(:textarea)
          else
            case field.to_s
            when "password"
              opts[:value] = nil
              standard_input(:password)
            when "email"
              standard_input(:email)
            when "phone", "fax"
              standard_input(:tel)
            when "url", "uri", "website"
              standard_input(:url)
            else
              standard_input(:text)
            end
          end
        end

        # Use number inputs for integers.
        def input_integer(sch)
          standard_input(:number)
        end

        # Use date inputs for dates.
        def input_date(sch)
          standard_input(:date)
        end

        # Use datetime inputs for datetimes.
        def input_datetime(sch)
          standard_input(:datetime)
        end

        # Use a text input for all other types.
        def input_other(sch)
          standard_input(:text)
        end

        # Allow overriding the given type using the :type option,
        # and set the :value option to the field value unless it
        # is overridden.
        def standard_input(type)
          type = opts.delete(:type) || type
          opts[:value] = obj.send(field) unless opts.has_key?(:value)
          _input(type, opts)
        end
      end

      # Helper module used for Sequel forms using ERB template integration.  Necessary for
      # proper subform handling when using such forms with partials.
      module ERBSequelForm
        # Capture the inside of the inputs, injecting it into the template
        # if a block is given, or returning it as a string if not.
        def subform(*, &block)
          if block
            capture(block){super}
          else
            capture{super}
          end
        end
      end
      SinatraSequelForm = ERBSequelForm

      class Form < ::Forme::Form
        include SequelForm
      end

      module InstanceMethods
        MUTEX = Mutex.new
        FORM_CLASSES = {::Forme::Form=>Form}

        # Configure the +form+ with support for <tt>Sequel::Model</tt>
        # specific code, such as support for nested attributes.
        def forme_config(form)
          form.namespaces << model.send(:underscore, model.name)
        end

        # Return subclass of base form that includes the necessary Sequel form methods.
        def forme_form_class(base)
          unless klass = MUTEX.synchronize{FORM_CLASSES[base]}
            klass = Class.new(base)
            klass.send(:include, SequelForm)
            klass.send(:include, ERBSequelForm) if defined?(::Forme::ERB::Form) && base == ::Forme::ERB::Form
            MUTEX.synchronize{FORM_CLASSES[base] = klass}
          end
          klass
        end

        # Return <tt>Forme::Input</tt> instance based on the given arguments.
        def forme_input(form, field, opts)
          SequelInput.new(self, form, field, opts).input
        end
      end
    end
  end
end
