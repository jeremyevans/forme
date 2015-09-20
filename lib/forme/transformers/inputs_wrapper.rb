module Forme
  # Default inputs_wrapper used by the library, uses a <fieldset>.
  #
  # Registered as :default.
  class InputsWrapper
    Forme.register_transformer(:inputs_wrapper, :default, new)

    # Wrap the inputs in a <fieldset>.  If the :legend
    # option is given, add a <legend> tag as the first
    # child of the fieldset.
    def call(form, opts)
      attr = opts[:attr] ? opts[:attr].dup : {}
      Forme.attr_classes(attr, 'inputs')
      if legend = opts[:legend]
        form.tag(:fieldset, attr) do
          form.emit(form.tag(:legend, opts[:legend_attr], legend))
          yield
        end
      else
        form.tag(:fieldset, attr, &Proc.new)
      end
    end
  end

  # Use a <fieldset> and an <ol> tag to wrap the inputs.
  #
  # Registered as :fieldset_ol.
  class InputsWrapper::FieldSetOL < InputsWrapper
    Forme.register_transformer(:inputs_wrapper, :fieldset_ol, new)

    # Wrap the inputs in a <fieldset> and a <ol> tag.
    def call(form, opts)
      super(form, opts){form.tag_(:ol){yield}}
    end
  end

  # Use an <ol> tag to wrap the inputs.
  #
  # Registered as :ol.
  class InputsWrapper::OL
    Forme.register_transformer(:inputs_wrapper, :ol, new)

    # Wrap the inputs in an <ol> tag
    def call(form, opts, &block)
      form.tag(:ol, opts[:attr], &block)
    end
  end

  # Use a <div> tag to wrap the inputs.
  #
  # Registered as :div.
  class InputsWrapper::Div
    Forme.register_transformer(:inputs_wrapper, :div, new)

    # Wrap the inputs in an <div> tag
    def call(form, opts, &block)
      form.tag(:div, opts[:attr], &block)
    end
  end

  # Use a <tr> tag to wrap the inputs.
  #
  # Registered as :tr.
  class InputsWrapper::TR
    Forme.register_transformer(:inputs_wrapper, :tr, new)

    # Wrap the inputs in an <tr> tag
    def call(form, opts, &block)
      form.tag(:tr, opts[:attr], &block)
    end
  end

  # Use a <table> tag to wrap the inputs.
  #
  # Registered as :table.
  class InputsWrapper::Table
    Forme.register_transformer(:inputs_wrapper, :table, new)

    # Wrap the inputs in a <table> tag.
    def call(form, opts, &block)
      attr = opts[:attr] ? opts[:attr].dup : {}
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
end
