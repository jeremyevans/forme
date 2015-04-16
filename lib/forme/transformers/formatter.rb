module Forme
  # The default formatter used by the library.  Any custom formatters should
  # probably inherit from this formatter unless they have very special needs.
  #
  # Unlike most other transformers which are registered as instances and use
  # a functional style, this class is registered as a class due to the large
  # amount of state it uses.
  #
  # Registered as :default.
  class Formatter
    Forme.register_transformer(:formatter, :default, self)

    # These options are copied directly from the options hash to the the
    # attributes hash, so they don't need to be specified in the :attr
    # option.  However, they can be specified in both places, and if so,
    # the :attr option version takes precedence.
    ATTRIBUTE_OPTIONS = [:name, :id, :placeholder, :value, :style]

    # Options copied from the options hash into the attributes hash,
    # where a true value in the options hash sets the attribute
    # value to the same name as the key.
    ATTRIBUTE_BOOLEAN_OPTIONS = [:autofocus, :required, :disabled]

    # Create a new instance and call it
    def self.call(input)
      new.call(input)
    end

    # The +Form+ instance for the receiver, taken from the +input+.
    attr_reader :form
    
    # The +Input+ instance for the receiver.  This is what the receiver
    # converts to the lower level +Tag+ form (or an array of them). 
    attr_reader :input
    
    # The attributes to to set on the lower level +Tag+ form returned.
    # This are derived from the +input+'s +opts+, but some processing is done on
    # them.
    attr_reader :attr
    
    # The +opts+ hash of the +input+.
    attr_reader :opts

    # Used to specify the value of the hidden input created for checkboxes.
    # Since the default for an unspecified checkbox value is 1, the default is
    # 0. If the checkbox value is 't', the hidden value is 'f', since that is
    # common usage for boolean values.
    CHECKBOX_MAP = Hash.new(0)
    CHECKBOX_MAP['t'] = 'f'

    # Transform the +input+ into a +Tag+ instance (or an array of them),
    # wrapping it with the +form+'s wrapper, and the form's +error_handler+
    # and +labeler+ if the +input+ has an <tt>:error</tt> or <tt>:label</tt>
    # options.
    def call(input)
      @input = input
      @form = input.form
      attr = input.opts[:attr]
      @attr = attr ? attr.dup : {}
      @opts = input.opts
      normalize_options

      tag = convert_to_tag(input.type)
      tag = wrap_tag_with_label(tag) if input.opts[:label]
      tag = wrap_tag_with_error(tag) if input.opts[:error]
      tag = wrap(:helper, tag) if input.opts[:help]
      wrap_tag(tag)
    end

    private

    # Dispatch to a format_<i>type</i> method if there is one that matches the
    # type, otherwise, call +_format_input+ with the given +type+.
    def convert_to_tag(type)
      meth = :"format_#{type}"
      if respond_to?(meth, true)
        send(meth)
      else
        _format_input(type)
      end
    end

    # If the checkbox has a name, will create a hidden input tag with the
    # same name that comes before this checkbox.  That way, if the checkbox
    # is checked, the web app will generally see the value of the checkbox, and
    # if it is not checked, the web app will generally see the value of the hidden
    # input tag.
    def format_checkbox
      @attr[:type] = :checkbox
      @attr[:checked] = :checked if @opts[:checked]
      if @attr[:name] && !@opts[:no_hidden]
        attr = {:type=>:hidden}
        unless attr[:value] = @opts[:hidden_value]
          attr[:value] = CHECKBOX_MAP[@attr[:value]]
        end
        attr[:id] = "#{@attr[:id]}_hidden" if @attr[:id]
        attr[:name] = @attr[:name]
        [tag(:input, attr), tag(:input)]
      else
        tag(:input)
      end
    end

    # For radio buttons, recognizes the :checked option and sets the :checked
    # attribute in the tag appropriately.
    def format_radio
      @attr[:checked] = :checked if @opts[:checked]
      @attr[:type] = :radio
      tag(:input)
    end

    DEFAULT_DATE_ORDER = [:year, '-'.freeze, :month, '-'.freeze, :day].freeze
    # Use a date input by default.  If the :as=>:select option is given,
    # use a multiple select box for the options.
    def format_date
      if @opts[:as] == :select
        values = {}
        if v = @attr[:value]
          v = Date.parse(v) unless v.is_a?(Date)
          values[:year], values[:month], values[:day] = v.year, v.month, v.day
        end
        _format_date_select(values, @opts[:order] || DEFAULT_DATE_ORDER)
      else
        _format_input(:date)
      end
    end

    DEFAULT_DATETIME_ORDER = [:year, '-'.freeze, :month, '-'.freeze, :day, ' '.freeze, :hour, ':'.freeze, :minute, ':'.freeze, :second].freeze
    # Use a datetime input by default.  If the :as=>:select option is given,
    # use a multiple select box for the options.
    def format_datetime
      if @opts[:as] == :select
        values = {}
        if v = @attr[:value]
          v = DateTime.parse(v) unless v.is_a?(Time) || v.is_a?(DateTime)
          values[:year], values[:month], values[:day], values[:hour], values[:minute], values[:second] = v.year, v.month, v.day, v.hour, v.min, v.sec
        end
        _format_date_select(values, @opts[:order] || DEFAULT_DATETIME_ORDER)
      else
        _format_input('datetime-local')
      end
    end

    DEFAULT_DATE_SELECT_OPS = {:year=>1900..2050, :month=>1..12, :day=>1..31, :hour=>0..23, :minute=>0..59, :second=>0..59}.freeze
    DATE_SELECT_FORMAT = '%02i'.freeze
    # Shared code for formatting dates/times as select boxes
    def _format_date_select(values, order)
      name = @attr[:name]
      id = @attr[:id]
      ops = DEFAULT_DATE_SELECT_OPS
      ops = ops.merge(@opts[:select_options]) if @opts[:select_options]
      first_input = true
      format = DATE_SELECT_FORMAT
      order.map do |x|
        next x if x.is_a?(String)
        opts = @opts.merge(:label=>nil, :wrapper=>nil, :error=>nil, :name=>"#{name}[#{x}]", :value=>values[x], :options=>ops[x].map{|y| [sprintf(format, y), y]})
        opts[:id] = if first_input
          first_input = false
          id
        else
          "#{id}_#{x}"
        end
        form._input(:select, opts).format
      end
    end

    # The default fallback method for handling inputs.  Assumes an input tag
    # with the type attribute set to input.
    def _format_input(type)
      @attr[:type] = type
      copy_options_to_attributes([:size, :maxlength])
      tag(:input)
    end

    # Takes a select input and turns it into a select tag with (possibly) option
    # children tags.
    def format_select
      @attr[:multiple] = :multiple if @opts[:multiple]
      copy_options_to_attributes([:size])

      os = process_select_optgroups(:_format_select_optgroup) do |label, value, sel, attrs|
        if value || sel
         attrs = attrs.dup
          attrs[:value] = value if value
          attrs[:selected] = :selected if sel
        end
        tag(:option, attrs, [label])
      end
      tag(:select, @attr, os)
    end

    # Use an optgroup around related options in a select tag.
    def _format_select_optgroup(group, options)
      group = {:label=>group} unless group.is_a?(Hash)
      tag(:optgroup, group, options)
    end

    # Use a fieldset/legend around related options in a checkbox or radio button set.
    def _format_set_optgroup(group, options)
      tag(:fieldset, {}, [tag(:legend, {}, [group])] + options)
    end

    def format_checkboxset
      @opts[:multiple] = true unless @opts.has_key?(:multiple)
      _format_set(:checkbox, :no_hidden=>true, :multiple=>true)
    end

    def format_radioset
      _format_set(:radio)
    end

    def _format_set(type, tag_attrs={})
      raise Error, "can't have radioset with no options" unless @opts[:optgroups] || @opts[:options]
      key = @opts[:key]
      name = @opts[:name]
      id = @opts[:id]
      if @opts[:error]
        @opts[:set_error] = @opts.delete(:error)
      end
      if @opts[:label]
        @opts[:set_label] = @opts.delete(:label)
      end
      tag_wrapper = @opts.delete(:tag_wrapper) || :default
      wrapper = Forme.transformer(:wrapper, @opts, @input.form_opts)

      tags = process_select_optgroups(:_format_set_optgroup) do |label, value, sel, attrs|
        value ||= label
        r_opts = attrs.merge(tag_attrs).merge(:label=>label||value, :label_attr=>{:class=>:option}, :wrapper=>tag_wrapper)
        r_opts[:value] ||= value if value
        r_opts[:checked] ||= :checked if sel

        if name
          r_opts[:name] ||= name
        end
        if id
          r_opts[:id] ||= "#{id}_#{value}"
        end
        if key
          r_opts[:key] ||= key
          r_opts[:key_id] ||= value
        end

        form._input(type, r_opts)
      end

      if @opts[:set_error]
        if (last_input = tags.last) && last_input.is_a?(Input)
          last_input.opts[:error] = @opts[:set_error]
        else
          tags << form._tag(:span, {:class=>'error_message'}, [@opts[:set_error]])
        end
      end
      tags.unshift(form._tag(:span, {:class=>:label}, @opts[:set_label])) if @opts[:set_label]
      wrapper.call(tags, form._input(type, opts)) if wrapper
      tags
    end

    # Formats a textarea.  Respects the following options:
    # :value :: Sets value as the child of the textarea.
    def format_textarea
      copy_options_to_attributes([:cols, :rows])
      if val = @attr.delete(:value)
        tag(:textarea, @attr, [val])
      else
        tag(:textarea)
      end
    end

    # Copy option values for given keys to the attributes unless the
    # attributes already have a value for the key.
    def copy_options_to_attributes(keys)
      keys.each do |k|
        if @opts.has_key?(k) && !@attr.has_key?(k)
          @attr[k] = @opts[k]
        end
      end
    end

    # Set attribute values for given keys to be the same as the key
    # unless the attributes already have a value for the key.
    def copy_boolean_options_to_attributes(keys)
      keys.each do |k|
        if @opts[k] && !@attr.has_key?(k)
          @attr[k] = k
        end
      end
    end

    # Normalize the options used for all input types.
    def normalize_options
      copy_options_to_attributes(ATTRIBUTE_OPTIONS)
      copy_boolean_options_to_attributes(ATTRIBUTE_BOOLEAN_OPTIONS)
      handle_key_option

      Forme.attr_classes(@attr, @opts[:class]) if @opts.has_key?(:class)
      Forme.attr_classes(@attr, 'error') if @opts[:error]

      if data = opts[:data]
        data.each do |k, v|
          sym = :"data-#{k}"
          @attr[sym] = v unless @attr.has_key?(sym)
        end
      end
    end

    # Have the :key option possibly set the name, id, and/or value attributes if not already set.
    def handle_key_option
      if key = @opts[:key]
        unless @attr[:name] || @attr['name']
          @attr[:name] = namespaced_name(key, @opts[:array] || @opts[:multiple])
          if !@attr.has_key?(:value) && !@attr.has_key?('value') && (values = @form.opts[:values])
            set_value_from_namespaced_values(namespaces, values, key)
          end
        end
        unless @attr[:id] || @attr['id']
          id = namespaced_id(key)
          if suffix = @opts[:key_id]
            id << '_' << suffix.to_s
          end
          @attr[:id] = id
        end
      end
    end

    # Array of namespaces to use for the input
    def namespaces
      input.form_opts[:namespace]
    end

    # Return a unique id attribute for the +field+, based on the current namespaces.
    def namespaced_id(field)
      "#{namespaces.join('_')}#{'_' unless namespaces.empty?}#{field}"
    end

    # Return a unique name attribute for the +field+, based on the current namespaces.
    # If +multiple+ is true, end the name with [] so that param parsing will treat
    # the name as part of an array.
    def namespaced_name(field, multiple=false)
      if namespaces.empty?
        if multiple
          "#{field}[]"
        else
          field
        end
      else
        root, *nsps = namespaces
        "#{root}#{nsps.map{|n| "[#{n}]"}.join}[#{field}]#{'[]' if multiple}"
      end
    end

    # Set the values option based on the (possibly nested) values
    # hash given, array of namespaces, and key.
    def set_value_from_namespaced_values(namespaces, values, key)
      namespaces.each do |ns|
        v = values[ns] || values[ns.to_s]
        return unless v
        values = v
      end

      @attr[:value] = values.fetch(key){values.fetch(key.to_s){return}}
    end

    # If :optgroups option is present, iterate over each of the groups
    # inside of it and create options for each group.  Otherwise, if
    # :options option present, iterate over it and create options.
    def process_select_optgroups(grouper, &block)
      os = if groups = @opts[:optgroups]
        groups.map do |group, options|
          send(grouper, group, process_select_options(options, &block))
        end
      else
        return unless @opts[:options]
        process_select_options(@opts[:options], &block)
      end

      if prompt = @opts[:add_blank]
        unless prompt.is_a?(String)
          prompt = Forme.default_add_blank_prompt
        end
        blank_attr = @opts[:blank_attr] || {}
        os.send(@opts[:blank_position] == :after ? :push : :unshift, yield([prompt, '', false, blank_attr]))
      end

      os
    end

    # Iterate over the given options, yielding the option text, value, whether it is selected, and any attributes.
    # The block should return an appropriate tag object.
    def process_select_options(os)
      if os
        vm = @opts[:value_method]
        tm = @opts[:text_method]
        sel = @opts[:selected] || @attr.delete(:value)

        if @opts[:multiple]
          sel = Array(sel)
          cmp = lambda{|v| sel.include?(v)}
        else
          cmp = lambda{|v| v == sel}
        end

        os.map do |x|
          attr = {}
          if tm
            text = x.send(tm)
            val = x.send(vm) if vm
          elsif x.is_a?(Array)
            text = x.first
            val = x.last

            if val.is_a?(Hash)
              value = val[:value]
              attr.merge!(val)
              val = value
            end
          else
            text = x
          end

          yield [text, val, val ? cmp.call(val) : cmp.call(text), attr]
        end
      end
    end

    # Create a +Tag+ instance related to the receiver's +form+ with the given
    # arguments.
    def tag(type, attr=@attr, children=nil)
      form._tag(type, attr, children)
    end

    # Wrap the tag for the given transformer type.
    def wrap(type, tag)
      Forme.transform(type, @opts, input.form_opts, tag, input)
    end

    # Wrap the tag with the form's +wrapper+.
    def wrap_tag(tag)
      wrap(:wrapper, tag)
    end

    # Wrap the tag with the form's +error_handler+.
    def wrap_tag_with_error(tag)
      wrap(:error_handler, tag)
    end

    # Wrap the tag with the form's +labeler+.
    def wrap_tag_with_label(tag)
      wrap(:labeler, tag)
    end
  end

  # Formatter that disables all input fields, 
  #
  # Registered as :disabled.
  class Formatter::Disabled < Formatter
    Forme.register_transformer(:formatter, :disabled, self)

    private

    # Unless the :disabled option is specifically set
    # to +false+, set the :disabled attribute on the
    # resulting tag.
    def normalize_options
      if @opts[:disabled] == false
        super
      else
        super
        @attr[:disabled] = :disabled
      end
    end
  end

  # Formatter that uses span tags with text for most input types,
  # and disables radio/checkbox inputs.
  #
  # Registered as :readonly.
  class Formatter::ReadOnly < Formatter
    Forme.register_transformer(:formatter, :readonly, self)

    private

    # Disabled checkbox inputs.
    def format_checkbox
      @attr[:disabled] = :disabled
      super
    end

    # Use a span with text instead of an input field.
    def _format_input(type)
      tag(:span, {}, @attr[:value])
    end

    # Disabled radio button inputs.
    def format_radio
      @attr[:disabled] = :disabled
      super
    end

    # Use a span with text of the selected values instead of a select box.
    def format_select
      t = super
      children = [t.children.select{|o| o.attr[:selected]}.map(&:children).join(', ')] if t.children
      tag(:span, {}, children)
    end

    # Use a span with text instead of a text area.
    def format_textarea
      tag(:span, {}, @attr[:value])
    end
  end
end
