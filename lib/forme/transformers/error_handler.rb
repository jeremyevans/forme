# frozen-string-literal: true

module Forme
  # Default error handler used by the library, using an "error" class
  # for the input field and a span tag with an "error_message" class
  # for the error message.
  #
  # Registered as :default.
  class ErrorHandler
    Forme.register_transformer(:error_handler, :default, new)

    # Return tag with error message span tag after it.
    def call(tag, input)
      attr = input.opts[:error_attr]
      attr = attr ? attr.dup : {}
      Forme.attr_classes(attr, 'error_message')

      if id = input.opts[:error_id]
        unless attr['id'] || attr[:id]
          attr['id'] = id
        end
      end

      [tag, input.tag(:span, attr, input.opts[:error])]
    end
  end

  class ErrorHandler::Set < ErrorHandler
    Forme.register_transformer(:error_handler, :set, new)

    def call(tag, input)
      last_tag = tag
      last_tag = last_tag.last while last_tag.is_a?(Array)
      return super unless last_tag.is_a?(Input)

      last_tag.opts[:error] = input.opts[:error]
      last_tag.opts[:error_attr] = input.opts[:error_attr] if input.opts[:error_attr]
      last_tag.opts[:error_handler] = :default
      tag
    end
  end
end
