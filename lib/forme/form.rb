module Forme
  # The +Form+ class is the main entry point to the library.  
  # Using the +form+, +input+, +tag+, and +inputs+ methods, one can easily build 
  # an abstract syntax tree of +Tag+ and +Input+ instances, which can be serialized
  # to a string using +to_s+.
  class Form
    # A hash of options for the form.
    attr_reader :opts

    # Set the default options for inputs by type.  This should be a hash with
    # input type keys and values that are hashes of input options.
    attr_reader :input_defaults

    # The hidden tags to automatically add to the form.
    attr_reader :hidden_tags

    # The namespaces if any for the receiver's inputs.  This can be used to
    # automatically setup namespaced class and id attributes.
    attr_accessor :namespaces

    # The +serializer+ determines how +Tag+ objects are transformed into strings.
    # Must respond to +call+ or be a registered symbol.
    attr_reader :serializer

    # Use appropriate Form subclass for object based on the current class, if the
    # object responds to +forme_form_class+.
    def self.new(obj=nil, opts={})
      if obj && obj.respond_to?(:forme_form_class) && !opts[:_forme_form_class_set]
        obj.forme_form_class(self).new(obj, opts.merge(:_forme_form_class_set=>true))
      else
        super
      end
    end

    # Create a +Form+ instance and yield it to the block,
    # injecting the opening form tag before yielding and
    # the closing form tag after yielding.
    #
    # Argument Handling:
    # No args :: Creates a +Form+ object with no options and not associated
    #            to an +obj+, and with no attributes in the opening tag.
    # 1 hash arg :: Treated as opening form tag attributes, creating a
    #               +Form+ object with no options.
    # 1 non-hash arg :: Treated as the +Form+'s +obj+, with empty options
    #                   and no attributes in the opening tag.
    # 2 hash args :: First hash is opening attributes, second hash is +Form+
    #                options.
    # 1 non-hash arg, 1-2 hash args :: First argument is +Form+'s obj, second is
    #                                  opening attributes, third if provided is
    #                                  +Form+'s options.
    def self.form(obj=nil, attr={}, opts={}, &block)
      f = if obj.is_a?(Hash)
        raise Error, "Can't provide 3 hash arguments to form" unless opts.empty?
        opts = attr
        attr = obj
        new(opts)
      else
        new(obj, opts)
      end

      ins = opts[:inputs]
      button = opts[:button]
      if ins || button
        block = Proc.new do |form|
          form._inputs(ins, opts) if ins
          yield form if block_given?
          form.emit(form.button(button)) if button
        end
      end

      f.form(attr, &block)
    end

    # Creates a +Form+ object. Arguments:
    # obj :: Sets the obj for the form.  If a hash, is merged with the +opts+ argument
    #        to set the opts.
    # opts :: A hash of options for the form
    def initialize(obj=nil, opts={})
      @opts = opts.merge(obj.is_a?(Hash) ? obj : {:obj=>obj})
      @opts[:namespace] = Array(@opts[:namespace])

      if obj && obj.respond_to?(:forme_config)
        obj.forme_config(self)
      end

      config = CONFIGURATIONS[@opts[:config]||Forme.default_config]
      copy_inputs_wrapper_from_wrapper(@opts)

      TRANSFORMER_TYPES.each do |t|
        case @opts[t]
        when Symbol
          @opts[t] = Forme.transformer(t, @opts[t], @opts)
        when nil
          unless @opts.has_key?(t)
            @opts[t] = Forme.transformer(t, config, @opts)
          end
        end
      end

      @serializer = @opts[:serializer]
      @input_defaults = @opts[:input_defaults] || {}
      @hidden_tags = @opts[:hidden_tags]
      @nesting = []
    end

    # Create a form tag with the given attributes.
    def form(attr={}, &block)
      tag(:form, attr, method(:hidden_form_tags), &block)
    end

    # Empty method designed to ease integration with other libraries where
    # Forme is used in template code and some output implicitly
    # created by Forme needs to be injected into the template output.
    def emit(tag)
    end

    # Creates an +Input+ with the given +field+ and +opts+ associated with
    # the receiver, and add it to the list of children to the currently
    # open tag.
    #
    # If the form is associated with an +obj+, or the :obj key exists in
    # the +opts+ argument, treats the +field+ as a call to the +obj+.  If
    # +obj+ responds to +forme_input+, that method is called with the +field+
    # and a copy of +opts+.  Otherwise, the field is used as a method call
    # on the +obj+ and a text input is created with the result.
    # 
    # If no +obj+ is associated with the receiver, +field+ represents an input
    # type (e.g. <tt>:text</tt>, <tt>:textarea</tt>, <tt>:select</tt>), and
    # an input is created directly with the +field+ and +opts+.
    def input(field, opts={})
      if opts.has_key?(:obj)
        opts = opts.dup
        obj = opts.delete(:obj)
      else
        obj = self.obj
      end
      input = if obj
        if obj.respond_to?(:forme_input)
          obj.forme_input(self, field, opts.dup)
        else
          opts = opts.dup
          opts[:key] = field unless opts.has_key?(:key)
          unless opts.has_key?(:value)
            opts[:value] = if obj.is_a?(Hash)
              obj[field]
            else
              obj.send(field)
            end
          end
          _input(:text, opts)
        end
      else
        _input(field, opts)
      end
      self << input
      input
    end

    # Create a new +Input+ associated with the receiver with the given
    # arguments, doing no other processing.
    def _input(*a)
      Input.new(self, *a)
    end

    # Creates a tag using the +inputs_wrapper+ (a fieldset by default), calls
    # input on each element of +inputs+, and yields if given a block.
    # You can use array arguments if you want inputs to be created with specific
    # options:
    #
    #   f.inputs([:field1, :field2])
    #   f.inputs([[:field1, {:name=>'foo'}], :field2])
    #
    # The given +opts+ are passed to the +inputs_wrapper+, and the default
    # +inputs_wrapper+ supports a <tt>:legend</tt> option that is used to
    # set the legend for the fieldset.
    #
    # +opts+ can also include transformer options itself (e.g. :wrapper), which
    # override the form's current transformer options for the duration of the block.
    # The exception is the :inputs_wrapper transformer option, which affects the
    # wrapper to use for this inputs call.  You can use the :nested_inputs_wrapper
    # option to set the default :inputs_wrapper option for the duration of the block.
    #
    # This can also be called with a single hash argument to just use an options hash:
    #
    #   f.inputs(:legend=>'Foo') do
    #     # ...
    #   end
    #
    # or even without any arguments:
    #
    #   f.inputs do
    #     # ...
    #   end
    def inputs(inputs=[], opts={}, &block)
      _inputs(inputs, opts, &block)
    end
    
    # Internals of #inputs, should be used internally by the library, where #inputs
    # is designed for external use. 
    def _inputs(inputs=[], opts={}) # :nodoc:
      if inputs.is_a?(Hash)
        opts = inputs.merge(opts)
        inputs = []
      end

      form_opts = {}
      form_opts[:inputs_wrapper] = opts[:nested_inputs_wrapper] if opts[:nested_inputs_wrapper]
      TRANSFORMER_TYPES.each do |t|
        if opts.has_key?(t) && t != :inputs_wrapper
          form_opts[t] = opts[t]
        end
      end

      Forme.transform(:inputs_wrapper, opts, @opts, self, opts) do
        with_opts(form_opts) do
          inputs.each do |i|
            emit(input(*i))
          end
          yield if block_given?
        end
      end
    end

    # Returns a string representing the opening of the form tag for serializers
    # that support opening tags.
    def open(attr)
      serializer.serialize_open(_tag(:form, attr)) if serializer.respond_to?(:serialize_open)
    end

    # Returns a string representing the closing of the form tag, for serializers
    # that support closing tags.
    def close
      serializer.serialize_close(_tag(:form)) if serializer.respond_to?(:serialize_close)
    end

    # Create a +Tag+ associated to the receiver with the given arguments and block,
    # doing no other processing.
    def _tag(*a, &block)
      tag = Tag.new(self, *a, &block)
    end

    # The object associated with this form, if any. If the +Form+ has an associated
    # obj, then calls to +input+ are assumed to be accessing fields of the object
    # instead to directly representing input types.
    def obj
      @opts[:obj]
    end

    # The current namespaces for the form, if any.
    def namespaces
      @opts[:namespace]
    end

    # Creates a +Tag+ associated to the receiver with the given arguments.
    # Add the tag to the the list of children for the currently open tag.
    # If a block is given, make this tag the currently open tag while inside
    # the block.
    def tag(*a, &block)
      tag = _tag(*a)
      self << tag
      nest(tag, &block) if block
      tag
    end

    # Aliased for tag.  Workaround for issue with rails plugin.
    def tag_(*a, &block) # :nodoc:
      tag(*a, &block)
    end

    # Creates a :submit +Input+ with the given opts, adding it to the list
    # of children for the currently open tag.
    def button(opts={})
      opts = {:value=>opts} if opts.is_a?(String)
      input = _input(:submit, opts)
      self << input
      input
    end

    # Add the +Input+/+Tag+ instance given to the currently open tag.
    def <<(tag)
      if n = @nesting.last
        n << tag
      end
    end

    # Calls the block for each object in objs, using with_obj with the given namespace
    # and an index namespace (starting at 0).
    def each_obj(objs, namespace=nil)
      objs.each_with_index do |obj, i|
        with_obj(obj, Array(namespace) + [i]) do
          yield obj, i
        end
      end
    end

    # Return a new string that will not be html escaped by the default serializer.
    def raw(s)
      Forme.raw(s)
    end

    # Marks the string as containing already escaped output.  Returns string given
    # by default, but subclasses for specific web frameworks can handle automatic
    # html escaping by overriding this.
    def raw_output(s)
      s
    end

    # Temporarily override the given object and namespace for the form.  Any given
    # namespaces are appended to the form's current namespace.
    def with_obj(obj, namespace=nil)
      with_opts(:obj=>obj, :namespace=>@opts[:namespace]+Array(namespace)) do
        yield obj
      end
    end

    # Temporarily override the opts for the form for the duration of the block.
    # This merges the given opts with the form's current opts, restoring
    # the previous opts before returning.
    def with_opts(opts)
      orig_opts = @opts
      @opts = orig_opts.merge(opts)
      copy_inputs_wrapper_from_wrapper(opts, @opts)
      yield
    ensure
      @opts = orig_opts if orig_opts
    end

    private

    # Copy the :wrapper option to :inputs_wrapper in output_opts if only :wrapper
    # is present in input_opts and the :wrapper option value is a shared wrapper.
    def copy_inputs_wrapper_from_wrapper(input_opts, output_opts=input_opts)
      if input_opts[:wrapper] && !input_opts[:inputs_wrapper] && SHARED_WRAPPERS.include?(input_opts[:wrapper])
        output_opts[:inputs_wrapper] = output_opts[:wrapper]
      end
    end

    # Return array of hidden tags to use for this form,
    # or nil if the form does not have hidden tags added automatically.
    def hidden_form_tags(form_tag)
      if hidden_tags
        tags = []
        hidden_tags.each do |hidden_tag|
          hidden_tag = hidden_tag.call(form_tag) if hidden_tag.respond_to?(:call)
          tags.concat(parse_hidden_tags(hidden_tag))
        end
        tags
      end
    end

    # Handle various types of hidden tags for the form.
    def parse_hidden_tags(hidden_tag)
      case hidden_tag
      when Array
        hidden_tag
      when Tag, String
        [hidden_tag]
      when Hash
        hidden_tag.map{|k,v| _tag(:input, :type=>:hidden, :name=>k, :value=>v)}
      when nil
        []
      else
        raise Error, "unhandled hidden_tag response: #{hidden_tag.inspect}"
      end
    end

    # Make the given tag the currently open tag, and yield.  After the
    # block returns, make the previously open tag the currently open
    # tag.
    def nest(tag)
      @nesting << tag
      yield self
    ensure
      @nesting.pop
    end

    # Return a serialized opening tag for the given tag.
    def serialize_open(tag)
      raw_output(serializer.serialize_open(tag)) if serializer.respond_to?(:serialize_open)
    end

    # Return a serialized closing tag for the given tag.
    def serialize_close(tag)
      raw_output(serializer.serialize_close(tag)) if serializer.respond_to?(:serialize_close)
    end
  end
end
