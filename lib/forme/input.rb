module Forme
  # High level abstract tag form, transformed by formatters into the lower
  # level +Tag+ form (or an array of them).
  class Input
    # The +Form+ object related to the receiver.
    attr_reader :form

    # The type of input, should be a symbol (e.g. :submit, :text, :select).
    attr_reader :type

    # The options hash for the Input.
    attr_reader :opts

    # The options hash in use by the form at the time of the Input's instantiation.
    attr_reader :form_opts

    # Set the +form+, +type+, and +opts+.
    def initialize(form, type, opts={})
      @form, @type = form, type
      defaults = form.input_defaults
      @opts = (defaults.fetch(type){defaults[type.to_s]} || {}).merge(opts)
      @form_opts = form.opts
    end

    # Replace the +opts+ by merging the given +hash+ into +opts+,
    # without modifying +opts+.
    def merge_opts(hash)
      @opts = @opts.merge(hash)
    end

    # Create a new +Tag+ instance with the given arguments and block
    # related to the receiver's +form+.
    def tag(*a, &block)
      form._tag(*a, &block)
    end

    # Return a string containing the serialized content of the receiver.
    def to_s
      form.raw_output(Forme.transform(:serializer, @opts, @form_opts, self))
    end

    # Transform the receiver into a lower level +Tag+ form (or an array
    # of them).
    def format
      Forme.transform(:formatter, @opts, @form_opts, self)
    end
  end
end
