module Forme
  # Default helper used by the library, using a spam with "helper" class
  #
  # Registered as :default.
  class Helper
    Forme.register_transformer(:helper, :default, new)

    # Return tag with error message span tag after it.
    def call(tag, input)
      attr = input.opts[:helper_attr]
      attr = attr ? attr.dup : {}
      Forme.attr_classes(attr, 'helper')
      [tag, input.tag(:span, attr, input.opts[:help])]
    end
  end
end

