# frozen-string-literal: true

module Forme
  register_config(:bs3, :formatter=>:bs3, :inputs_wrapper=>:bs3, :wrapper=>:bs3, :error_handler=>:bs3, :serializer=>:bs3, :labeler=>:bs3, :tag_wrapper=>:bs3, :set_wrapper=>:div)

  # BS3 Boostrap formatted error handler which adds a span tag 
  # with "help-block with-errors" classes for the error message.
  # 
  # Uses [github.com/1000hz/bootstrap-validator] formatting.
  # 
  # Note! The default "error" class on the input is being removed.
  #
  # Registered as :bs3.
  class ErrorHandler::Bootstrap3 < ErrorHandler
    Forme.register_transformer(:error_handler, :bs3, new)

    # Return tag with error message span tag after it.
    def call(tag, input)
      if tag.is_a?(Tag)
        tag.attr[:class] = tag.attr[:class].to_s.gsub(/\s*error\s*/,'')
        tag.attr.delete(:class) if tag.attr[:class].to_s == ''
      end
      attr = input.opts[:error_attr]
      attr = attr ? attr.dup : {}
      Forme.attr_classes(attr, 'help-block with-errors')
      return [tag] if input.opts[:skip_error_message]

      case input.type
      when :submit, :reset
        [tag]
      when :textarea
        input.opts[:wrapper] = :bs3
        if input.opts[:wrapper_attr]
          Forme.attr_classes(input.opts[:wrapper_attr], 'has-error')
        else
          input.opts[:wrapper_attr] = { :class => 'has-error' }
        end
        [ tag, input.tag(:span, attr, input.opts[:error]) ]
        
      when :select
        input.opts[:wrapper] = :bs3
        if input.opts[:wrapper_attr]
          Forme.attr_classes(input.opts[:wrapper_attr], 'has-error')
        else
          input.opts[:wrapper_attr] = { :class => 'has-error' }
        end
        [ tag, input.tag(:span, attr, input.opts[:error]) ]
        
      when :checkbox, :radio
        
        input.opts[:wrapper] = :div
        if input.opts[:wrapper_attr]
          Forme.attr_classes(input.opts[:wrapper_attr], 'has-error')
        else
          input.opts[:wrapper_attr] = { :class => 'has-error' }
        end
        
        [ 
          input.tag(:div, { :class=> input.type.to_s }, [tag] ), 
          input.tag(:span, attr, input.opts[:error]) 
        ]
      else
        if input.opts[:wrapper_attr]
          Forme.attr_classes(input.opts[:wrapper_attr], 'has-error')
        else
          input.opts[:wrapper_attr] = { :class => 'has-error' }
        end
        [tag, input.tag(:span, attr, input.opts[:error])]
      end
    end
  end

  class Formatter::Bs3 < Formatter
    Forme.register_transformer(:formatter, :bs3, self)

    private

    # Copied to remove .error from class attrs
    def normalize_options
      copy_options_to_attributes(ATTRIBUTE_OPTIONS)
      copy_boolean_options_to_attributes(ATTRIBUTE_BOOLEAN_OPTIONS)
      handle_key_option

      Forme.attr_classes(@attr, @opts[:class]) if @opts.has_key?(:class)
      # Forme.attr_classes(@attr, 'error') if @opts[:error]

      if data = opts[:data]
        data.each do |k, v|
          sym = :"data-#{k}"
          @attr[sym] = v unless @attr.has_key?(sym)
        end
      end
    end

    def _add_set_error(tags)
      tags << input.tag(:span, {:class=>'help-block with-errors'}, @opts[:set_error])
    end

    def format_radioset
      @opts[:wrapper_attr] ||= {}
      klasses = 'radioset'
      klasses = @opts[:error] || @opts[:set_error] ? "#{klasses} has-error" : klasses
      Forme.attr_classes(@opts[:wrapper_attr], klasses)
      super
    end

    def format_checkboxset
      @opts[:wrapper_attr] ||= {}
      klasses = 'checkboxset'
      klasses = @opts[:error] || @opts[:set_error] ? "#{klasses} has-error" : klasses
      Forme.attr_classes(@opts[:wrapper_attr], klasses)
      super
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

      tag_wrapper = Forme.transformer(:tag_wrapper, @opts.delete(:tag_wrapper), @input.form_opts) || :default
      wrapper = @opts.fetch(:wrapper){@opts[:wrapper] = @input.form_opts[:set_wrapper] || @input.form_opts[:wrapper]}
      wrapper = Forme.transformer(:wrapper, wrapper)

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
       _add_set_error(tags)
      end

      tags.unshift(form._tag(:label, {}, @opts[:set_label])) if @opts[:set_label]

      tags
    end
    
  end
  
  # Formatter that adds "readonly" for most input types,
  # and disables select/radio/checkbox inputs.
  #
  # Registered as :bs3_readonly.
  class Formatter::Bs3ReadOnly < Formatter
    Forme.register_transformer(:formatter, :bs3_readonly, self)

    private

    # Disabled checkbox inputs.
    def format_checkbox
      @attr[:disabled] = :disabled
      super
    end

    # Use a span with text instead of an input field.
    def _format_input(type)
      @attr[:readonly] = :readonly
      super
    end

    # Disabled radio button inputs.
    def format_radio
      @attr[:disabled] = :disabled
      super
    end

    # Use a span with text of the selected values instead of a select box.
    def format_select
      @attr[:disabled] = :disabled
      super
    end

    # Use a span with text instead of a text area.
    def format_textarea
      @attr[:readonly] = :readonly
      super
    end
  end

  # Use a <fieldset> tag to wrap the inputs.
  #
  # Registered as :bs3.
  class InputsWrapper::Bootstrap3
    Forme.register_transformer(:inputs_wrapper, :bs3, new)

    def call(form, opts, &block)
      attr = opts[:attr] ? opts[:attr].dup : {}
      Forme.attr_classes(attr, 'inputs')
      if legend = opts[:legend]
        form.tag(:fieldset, attr) do
          form.emit(form.tag(:legend, opts[:legend_attr], legend))
          yield
        end
      else
        form.tag(:fieldset, attr, &block)
      end
    end
  end

  # Use a <table class="table"> tag to wrap the inputs.
  #
  # Registered as :bs3_table.
  class InputsWrapper::Bs3Table
    Forme.register_transformer(:inputs_wrapper, :bs3_table, new)

    # Wrap the inputs in a <table> tag.
    def call(form, opts, &block)
      attr = opts[:attr] ? opts[:attr].dup : { :class=>'table table-bordered'}
      form.tag(:table, attr) do
        if legend = opts[:legend]
          form.emit(form.tag(:caption, opts[:legend_attr], legend))
        end

        if (labels = opts[:labels]) && !labels.empty?
          form.emit(form.tag(:tr, {}, labels.map{|l| form._tag(:th, {}, l)}))
        end

        yield
      end
    end
  end

  # Labeler that creates BS3 label tags referencing the the given tag's id 
  # using a +for+ attribute. Requires that all tags with labels have +id+ fields.
  #
  # Registered as :bs3.
  class Labeler::Bootstrap3
    Forme.register_transformer(:labeler, :bs3, new)

    # Return an array with a label tag as the first entry and +tag+ as
    # a second entry.  If the +input+ has a :label_for option, use that,
    # otherwise use the input's :id option.  If neither the :id or
    # :label_for option is used, the label created will not be
    # associated with an input.
    def call(tag, input)
      unless id = input.opts[:id]
        if key = input.opts[:key]
          namespaces = input.form_opts[:namespace]
          id = "#{namespaces.join('_')}#{'_' unless namespaces.empty?}#{key}"
          if key_id = input.opts[:key_id]
            id += "_#{key_id.to_s}"
          end
        end
      end

      label_attr = input.opts[:label_attr]
      label_attr = label_attr ? label_attr.dup : {}
      
      label_attr[:for] = label_attr[:for] === false ? nil : input.opts.fetch(:label_for, id)
      label = input.opts[:label]
      lpos = input.opts[:label_position] || ([:radio, :checkbox].include?(input.type) ? :after : :before)
      
      case input.type
      when :checkbox, :radio
        label = if lpos == :before
          [label, ' ', tag]
        else
          [tag, ' ', label]
        end
        input.tag(:label, label_attr, label)
      when :submit
        [tag]
      else
        label = input.tag(:label, label_attr, [input.opts[:label]])
        if lpos == :after
          [tag, ' ', label]
        else
          [label, ' ', tag]
        end
      end
    end
  end
  
  # Wraps inputs with <div class="form-group">
  class Wrapper::Bootstrap3 < Wrapper
    # Wrap the input in the tag of the given type.

    def call(tag, input)
      attr = input.opts[:wrapper_attr] ? input.opts[:wrapper_attr].dup : { }
      klass = attr[:class] ? attr[:class].split(' ').unshift('form-group').uniq : ['form-group']
      
      case input.type
      when :submit, :reset
        klass.delete('form-group')
        attr[:class] = klass.sort.uniq.join(' ').strip
        attr.delete(:class) if attr[:class].empty?
        [tag]
      when :radio, :checkbox
        klass.delete('form-group')
        klass.unshift( input.type.to_s )
        attr[:class] = klass.sort.uniq.join(' ').strip
        [input.tag(:div, attr, tag)]
      when :hidden
        super
      else
        attr[:class] = klass.sort.uniq.join(' ').strip
        [input.tag(:div, attr, [tag])]
      end

    end
    
    Forme.register_transformer(:wrapper, :bs3, new)
  end
  
  # Serializer class that converts tags to BS3 bootstrap tags.
  #
  # Registered at :bs3.
  class Serializer::Bootstrap3 < Serializer
    Forme.register_transformer(:serializer, :bs3, new)

    def call(tag)
      # All textual <input>, <textarea>, and <select> elements with .form-control
      case tag
      when Tag
        case tag.type
        when :input
          # default to <input type="text"...> if not set
          tag.attr[:type] = :text if tag.attr[:type].nil?
          
          case tag.attr[:type].to_sym
          when :checkbox, :radio, :hidden
            # .form-control class causes rendering problems, so remove if found
            tag.attr[:class].gsub!(/\s*form-control\s*/,'') if tag.attr[:class]
            tag.attr[:class] = nil if tag.attr[:class] && tag.attr[:class].empty?
            
          when :file
            tag.attr[:class] = nil unless tag.attr[:class] && tag.attr[:class].strip != ''
          
          when :submit, :reset
            klass = ['btn', 'btn-default']
            if tag.attr[:class] && tag.attr[:class].strip != ''
              tag.attr[:class].split(' ').each { |c| klass.push c }
            end
            tag.attr[:class] = klass.uniq
            ['btn-primary','btn-success', 'btn-info', 'btn-warning','btn-danger',
              'btn-outline','btn-link' 
            ].each do |k|
              tag.attr[:class].delete('btn-default') if tag.attr[:class].include?(k)
            end
            tag.attr[:class].join(' ')
            
          else
            klass = tag.attr[:class] ? "form-control #{tag.attr[:class].to_s}" : ''
            tag.attr[:class] = "form-control #{klass.gsub(/\s*form-control\s*/,'')}".strip
          end
          
          return "<#{tag.type}#{attr_html(tag.attr)}/>"
          
        when :textarea, :select
          klass = tag.attr[:class] ? "form-control #{tag.attr[:class].to_s}" : ''
          tag.attr[:class] = "form-control #{klass.gsub(/\s*form-control\s*/,'')}".strip
          return "#{serialize_open(tag)}#{call(tag.children)}#{serialize_close(tag)}"
        else
          super
        end
      else
        super
      end
    end
  end
end
