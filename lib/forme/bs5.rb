# frozen-string-literal: true

module Forme
  register_config(:bs5, formatter: :bs5, wrapper: :bs5, error_handler: :bs5, serializer: :bs5, labeler: :bs5, helper: :bs5, tag_wrapper: :bs5, set_wrapper: :div)

  # Update the <tt>:class</tt> entry in the +attr+ hash with the given +classes+,
  # adding the classes before any existing classes.
  def self.attr_classes_after(attr, *classes)
    attr[:class] = merge_classes(*classes, attr[:class])
  end

  class ErrorHandler::Bootstrap5
    Forme.register_transformer(:error_handler, :bs5, new)

    def call(tags, input)
      attr = input.opts[:error_attr]
      attr = attr ? attr.dup : {}

      unless attr[:class] && attr[:class].include?("invalid-tooltip")
        Forme.attr_classes(attr, "invalid-feedback")
      end

      attr[:id] ||= input.opts[:error_id]

      [tags, input.tag(:div, attr, input.opts[:error])]
    end
  end

  class Formatter::Bootstrap5 < Formatter
    Forme.register_transformer(:formatter, :bs5, self)

    private

    def normalize_options
      super

      if @opts[:error]
        # remove "error" class
        @attr[:class] = @attr[:class].to_s.sub(/\s*error$/,'')
        @attr.delete(:class) if @attr[:class].to_s == ''

        Forme.attr_classes(@attr, "is-invalid")
      end

      if @opts[:help]
        if @opts[:helper_attr] && @opts[:helper_attr][:id]
          @attr["aria-describedby"] ||= @opts[:helper_attr][:id]
        end
      end
    end
  end

  # Formatter that adds "readonly" for most input types,
  # and disables select/radio/checkbox inputs.
  #
  # Registered as :bs5_readonly.
  class Formatter::Bs5ReadOnly < Formatter
    Forme.register_transformer(:formatter, :bs5_readonly, self)

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

  # Use a <table class="table"> tag to wrap the inputs.
  #
  # Registered as :bs5_table.
  class InputsWrapper::Bs5Table
    Forme.register_transformer(:inputs_wrapper, :bs5_table, new)

    # Wrap the inputs in a <table> tag.
    def call(form, opts, &block)
      attr = opts[:attr] ? opts[:attr].dup : { :class=>'table table-bordered'}
      form.tag(:table, attr) do
        if legend = opts[:legend]
          form.tag(:caption, opts[:legend_attr], legend)
        end

        if (labels = opts[:labels]) && !labels.empty?
          form.tag(:tr, {}, labels.map{|l| form._tag(:th, {}, l)})
        end

        yield
      end
    end
  end

  class Labeler::Bootstrap5 < Labeler::Explicit
    Forme.register_transformer(:labeler, :bs5, new)

    def call(tag, input)
      floating_label = (input.opts[:wrapper_attr] || {})[:class].to_s.include?("form-floating")
      input.opts[:label_position] ||= :after if floating_label

      tags = super
      return tags if floating_label

      attr = tags.find { |tag| tag.is_a?(Tag) && tag.type == :label }.attr

      label_class = case input.type
      when :radio, :checkbox
        "form-check-label"
      else
        "form-label"
      end
      Forme.attr_classes_after(attr, label_class)

      tags
    end
  end

  class Helper::Bootstrap5
    Forme.register_transformer(:helper, :bs5, new)

    def call(tag, input)
      attr = input.opts[:helper_attr]
      attr = attr ? attr.dup : {}
      Forme.attr_classes(attr, 'form-text')
      [tag, input.tag(:div, attr, input.opts[:help])]
    end
  end

  class Wrapper::Bootstrap5 < Wrapper
    Forme.register_transformer(:wrapper, :bs5, new)

    def call(tag, input)
      attr = input.opts[:wrapper_attr] ? input.opts[:wrapper_attr].dup : { }

      case input.type
      when :submit, :reset, :hidden
        super
      when :radio, :checkbox
        Forme.attr_classes_after(attr, "form-check")
        input.tag(:div, attr, super)
      else
        input.tag(:div, attr, super)
      end
    end
  end

  class Serializer::Bootstrap5 < Serializer
    Forme.register_transformer(:serializer, :bs5, new)

    BUTTON_STYLES = %w[
      btn-primary btn-secondary btn-success btn-danger btn-warning btn-info btn-light btn-dark btn-link
      btn-outline-primary btn-outline-secondary btn-outline-success btn-outline-danger btn-outline-warning btn-outline-info btn-outline-light btn-outline-dark
    ].freeze

    def call(tag)
      return super unless tag.is_a?(Tag)

      attr_class = case tag.type
      when :input
        # default to <input type="text"...> if not set
        tag.attr[:type] = :text if tag.attr[:type].nil?

        case tag.attr[:type].to_sym
        when :checkbox, :radio
          "form-check-input"
        when :range
          "form-range"
        when :color
          %w"form-control form-control-color"
        when :submit, :reset
          classes = ["btn"]
          classes << "btn-primary" if (tag.attr[:class].to_s.split(" ") & BUTTON_STYLES).empty?
          classes
        when :hidden
          # nothing
        else
          unless tag.attr[:class] && tag.attr[:class].include?("form-control-plaintext")
            "form-control"
          end
        end
      when :textarea
        "form-control"
      when :select
        "form-select"
      end
      Forme.attr_classes_after(tag.attr, *attr_class) if attr_class

      super
    end
  end
end
