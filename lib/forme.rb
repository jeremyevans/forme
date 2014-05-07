require 'date'
require 'bigdecimal'
require 'forme/version'

# Forme is designed to make creating HTML forms easier.  Flexibility and
# simplicity are primary objectives.  The basic usage involves creating
# a <tt>Forme::Form</tt> instance, and calling +input+ and +tag+ methods
# to return html strings for widgets, but it could also be used for
# serializing to other formats, or even as a DSL for a GUI application.
#
# In order to be flexible, Forme stores tags in abstract form until
# output is requested.  There are two separate abstract <i>forms</i> that Forme
# uses.  One is <tt>Forme::Input</tt>, and the other is <tt>Forme::Tag</tt>.
# <tt>Forme::Input</tt> is a high level abstract form, while <tt>Forme::Tag</tt>
# is a low level abstract form.
#
# The difference between <tt>Forme::Input</tt> and <tt>Forme::Tag</tt> 
# is that <tt>Forme::Tag</tt> directly represents the underlying html
# tag, containing a type, optional attributes, and children, while the
# <tt>Forme::Input</tt> is more abstract and attempts to be user friendly.
# For example, these both compile by default to the same select tag:
# 
#   f.input(:select, :options=>[['foo', 1]])
#   # or
#   f.tag(:select, {}, [f.tag(:option, {:value=>1}, ['foo'])])
#
# The processing of high level <tt>Forme::Input</tt>s into raw html
# data is broken down to the following steps (called transformers):
#
# * +Formatter+: converts a <tt>Forme::Input</tt> instance into a
#   <tt>Forme::Tag</tt> instance (or array of them).
# * +ErrorHandler+: If the <tt>Forme::Input</tt> instance has a error,
#   takes the formatted tag and marks it as having the error.
# * +Labeler+: If the <tt>Forme::Input</tt> instance has a label,
#   takes the formatted output and labels it.
# * +Wrapper+: Takes the output of the labeler (or formatter if
#   no label), and wraps it in another tag (or just returns it
#   directly).
# * +Serializer+: converts a <tt>Forme::Tag</tt> instance into a
#   string.
#
# Technically, only the +Serializer+ is necessary.  The +input+
# and +tag+ methods return +Input+ and +Tag+ objects.  These objects
# both have +to_s+ defined to call the appropriate +Serializer+ with
# themselves.  The +Serializer+ calls the appropriate +Formatter+ if
# it encounters an +Input+ instance, and attempts to serialize the
# output of that (which is usually a +Tag+ instance).  It is up to
# the +Formatter+ to call the +Labeler+ and/or +ErrorHandler+ (if
# necessary) and the +Wrapper+.
# 
# There is also an +InputsWrapper+ transformer, that is called by
# <tt>Forme::Form#inputs</tt>.  It's used to wrap up a group of
# related options (in a fieldset by default).
#
# The <tt>Forme::Form</tt> object takes the 6 transformers as options (:formatter,
# :labeler, :error_handler, :wrapper, :inputs_wrapper, and :serializer), all of which
# should be objects responding to +call+ (so you can use +Proc+s) or be symbols
# registered with the library using <tt>Forme.register_transformer</tt>:
#
#   Forme.register_transformer(:wrapper, :p){|t| t.tag(:p, {}, t)}
#
# Most of the transformers can be overridden on a per instance basis by
# passing the appopriate option to +input+ or +inputs+:
#
#   f.input(:name, :wrapper=>:p)
module Forme
  # Exception class for exceptions raised by Forme.
  class Error < StandardError
  end

  @default_add_blank_prompt = nil
  @default_config = :default
  class << self
    # Set the default configuration to use if none is explicitly
    # specified (default: :default).
    attr_accessor :default_config

    # The default prompt to use for the :add_blank option (default: nil).
    attr_accessor :default_add_blank_prompt
  end

  # Array of all supported transformer types.
  TRANSFORMER_TYPES = [:formatter, :serializer, :wrapper, :error_handler, :labeler, :inputs_wrapper]

  # Hash storing all configurations.  Configurations are groups of related transformers,
  # so that you can specify a single :config option when creating a +Form+ and have
  # all of the transformers set from that.
  CONFIGURATIONS = {:default=>{}}
  
  # Main hash storing the registered transformers.  Maps transformer type symbols to subhashes
  # containing the registered transformers for that type.  Those subhashes should have symbol
  # keys and values that are either classes or objects that respond to +call+.
  TRANSFORMERS = {}

  TRANSFORMER_TYPES.each do |t|
    CONFIGURATIONS[:default][t] = :default
    TRANSFORMERS[t] = {}
  end

  # Register a new transformer with this library. Arguments:
  # +type+ :: Transformer type symbol
  # +sym+ :: Transformer name symbol
  # <tt>obj/block</tt> :: Transformer to associate with this symbol.  Should provide either
  #                       +obj+ or +block+, but not both.  If +obj+ is given, should be
  #                       either a +Class+ instance or it should respond to +call+.  If a
  #                       +Class+ instance is given, instances of that class should respond
  #                       to +call+, and a new instance of that class should be used
  #                       for each transformation.
  def self.register_transformer(type, sym, obj=nil, &block)
    raise Error, "Not a valid transformer type" unless TRANSFORMERS.has_key?(type)
    raise Error, "Must provide either block or obj, not both" if obj && block
    TRANSFORMERS[type][sym] = obj||block
  end

  # Register a new configuration.  Type is the configuration name symbol,
  # and hash maps transformer type symbols to transformer name symbols.
  def self.register_config(type, hash)
    CONFIGURATIONS[type] = CONFIGURATIONS[hash.fetch(:base, :default)].merge(hash)
  end

  register_config(:formtastic, :wrapper=>:li, :inputs_wrapper=>:fieldset_ol, :labeler=>:explicit)

  # Call <tt>Forme::Form.form</tt> with the given arguments and block.
  def self.form(*a, &block)
    Form.form(*a, &block)
  end

  # Update the <tt>:class</tt> entry in the +attr+ hash with the given +classes+.
  def self.attr_classes(attr, *classes)
    attr[:class] = merge_classes(attr[:class], *classes)
  end

  # Return a string that includes all given class strings
  def self.merge_classes(*classes)
    classes.compact.join(' ')
  end

  # The +Form+ class is the main entry point to the library.  
  # Using the +form+, +input+, +tag+, and +inputs+ methods, one can easily build 
  # an abstract syntax tree of +Tag+ and +Input+ instances, which can be serialized
  # to a string using +to_s+.
  class Form
    # The object related to the receiver, if any.  If the +Form+ has an associated
    # obj, then calls to +input+ are assumed to be accessing fields of the object
    # instead to directly representing input types.
    attr_reader :obj

    # A hash of options for the Form. Currently, the following are recognized by
    # default:
    # :obj :: Sets the +obj+ attribute
    # :error_handler :: Sets the +error_handler+ for the form
    # :formatter :: Sets the +formatter+ for the form
    # :hidden_tags :: Sets the hidden tags to automatically add to this form.
    # :input_defaults :: Sets the default options for each input type
    # :inputs_wrapper :: Sets the +inputs_wrapper+ for the form
    # :labeler :: Sets the +labeler+ for the form
    # :wrapper :: Sets the +wrapper+ for the form
    # :serializer :: Sets the +serializer+ for the form
    # :values :: The values from a previous form submission, used to set default
    #            values for inputs when the inputs use the :key option.
    attr_reader :opts

    # The +formatter+ determines how the +Input+s created are transformed into
    # +Tag+ objects. Must respond to +call+ or be a registered symbol.
    attr_reader :formatter

    # The +error_handler+ determines how to to mark tags as containing errors.
    # Must respond to +call+ or be a registered symbol.
    attr_reader :error_handler

    # The +labeler+ determines how to label tags.  Must respond to +call+ or be
    # a registered symbol.
    attr_reader :labeler

    # The +wrapper+ determines how (potentially labeled) tags are wrapped.  Must
    # respond to +call+ or be a registered symbol.
    attr_reader :wrapper

    # Set the default options for inputs by type.  This should be a hash with
    # input type string keys and values that are hashes of input options.
    attr_reader :input_defaults

    # The +inputs_wrapper+ determines how calls to +inputs+ are wrapped.  Must
    # respond to +call+ or be a registered symbol.
    attr_reader :inputs_wrapper

    # The +serializer+ determines how +Tag+ objects are transformed into strings.
    # Must respond to +call+ or be a registered symbol.
    attr_reader :serializer

    # The hidden tags to automatically add to the form.  If set, this should be an
    # array, where elements are one of the following types:
    # String, Array, Forme::Tag :: Added directly as a child of the form tag.
    # Hash :: Adds a hidden tag for each entry, with keys as the name of the hidden
    #         tag and values as the value of the hidden tag.
    # Proc :: Will be called with the form tag object, and should return an instance
    #         of one of the handled types (or nil to not add a tag).
    attr_reader :hidden_tags

    # The namespaces if any for the receiver's inputs.  This can be used to
    # automatically setup namespaced class and id attributes.
    attr_accessor :namespaces

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
    # opts :: A hash of options for the form, see +opts+ attribute for details on
    #         available options.
    def initialize(obj=nil, opts={})
      if obj.is_a?(Hash)
        @opts = obj.merge(opts)
        @obj = @opts.delete(:obj)
      else
        @obj = obj
        @opts = opts
      end

      @namespaces = []
      if ns = @opts[:namespace]
        Array(ns).each{|n| push_namespace(n)}
      end

      if @obj && @obj.respond_to?(:forme_config)
        @obj.forme_config(self)
      end

      config = CONFIGURATIONS[@opts[:config]||Forme.default_config]
      TRANSFORMER_TYPES.each{|k| instance_variable_set(:"@#{k}", transformer(k, @opts.fetch(k, config[k])))}
      @input_defaults = @opts[:input_defaults] || {}
      @hidden_tags = @opts[:hidden_tags]
      @nesting = []
    end

    # If there is a related transformer, call it with the given +args+ and +block+.
    # Otherwise, attempt to return the initial input without modifying it.
    def transform(type, trans_name, *args, &block)
      if trans = transformer(type, trans_name)
        trans.call(*args, &block)
      else
        case type
        when :inputs_wrapper
          yield
        when :labeler, :error_handler, :wrapper
          args.first
        else
          raise Error, "No matching #{type}: #{trans_name.inspect}"
        end
      end
    end

    # Get the related transformer for the given transformer type.  Output depends on the type
    # of +trans+:
    # +Symbol+ :: Assume a request for a registered transformer, so look it up in the +TRANSFORRMERS+ hash.
    # +Hash+ :: If +type+ is also a key in +trans+, return the related value from +trans+, unless the related
    #           value is +nil+, in which case, return +nil+.  If +type+ is not a key in +trans+, use the
    #           default transformer for the receiver.
    # +nil+ :: Assume the default transformer for this receiver.
    # otherwise :: return +trans+ directly if it responds to +call+, and raise an +Error+ if not.
    def transformer(type, trans)
      case trans
      when Symbol
        TRANSFORMERS[type][trans] || raise(Error, "invalid #{type}: #{trans.inspect} (valid #{type}s: #{TRANSFORMERS[type].keys.map{|k| k.inspect}.join(', ')})")
      when Hash
        if trans.has_key?(type)
          if v = trans[type]
            transformer(type, v)
          end
        else
          transformer(type, nil)
        end
      when nil
        send(type)
      else
        if trans.respond_to?(:call)
          trans
        else
          raise Error, "#{type} #{trans.inspect} must respond to #call"
        end
      end
    end

    # Create a form tag with the given attributes.
    def form(attr={}, &block)
      tag(:form, attr, method(:hidden_form_tags), &block)
    end

    # Formats the +input+ using the +formatter+.
    def format(input)
      transform(:formatter, input.opts, input)
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
          opts[:name] = field unless opts.has_key?(:name)
          opts[:id] = field unless opts.has_key?(:id)
          opts[:value] = obj.send(field) unless opts.has_key?(:value)
          _input(:text, opts)
        end
      else
        _input(field, opts)
      end
      use_serializer(input) if input.is_a?(Array)
      self << input
      input
    end

    # Create a new +Input+ associated with the receiver with the given
    # arguments, doing no other processing.
    def _input(*a)
      Input.new(self, *a)
    end

    # Creates a tag using the +inputs_wrapper+ (a fieldset by default), calls
    # input on each element of +inputs+, and yields to if given a block.
    # You can use array arguments if you want inputs to be created with specific
    # options:
    #
    #   inputs([:field1, :field2])
    #   inputs([[:field1, {:name=>'foo'}], :field2])
    #
    # The given +opts+ are passed to the +inputs_wrapper+, and the default
    # +inputs_wrapper+ supports a <tt>:legend</tt> option that is used to
    # set the legend for the fieldset.
    def inputs(*a, &block)
      _inputs(*a, &block)
    end
    
    # Internals of #inputs, should be used internally by the library, where #inputs
    # is designed for external use.
    def _inputs(inputs=[], opts={})
      if inputs.is_a?(Hash)
        opts = inputs.merge(opts)
        inputs = []
      end
      transform(:inputs_wrapper, opts, self, opts) do
        inputs.each do |i|
          emit(input(*i))
        end
        yield if block_given?
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

    def tag_(*a, &block)
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

    # Serializes the +tag+ using the +serializer+.
    def serialize(tag)
      serializer.call(tag)
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

    private

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

    # Extend +obj+ with +Serialized+ and associate it with the receiver, such
    # that calling +to_s+ on the object will use the receiver's serializer
    # to generate the resulting string.
    def use_serializer(obj)
      obj.extend(Serialized)
      obj._form = self
      obj
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

    # Add to the current stack of namespaces.
    def push_namespace(namespace)
      @namespaces << namespace
    end

    # Remove top value from the current stack of namespaces.
    def pop_namespace
      @namespaces.pop
    end

  end

  # High level abstract tag form, transformed by formatters into the lower
  # level +Tag+ form (or an array of them).
  class Input
    # The +Form+ object related to the receiver.
    attr_reader :form

    # The type of input, should be a symbol (e.g. :submit, :text, :select).
    attr_reader :type

    # The options hash for the Input.
    attr_reader :opts

    # Set the +form+, +type+, and +opts+.
    def initialize(form, type, opts={})
      @form, @type = form, type
      @opts = (form.input_defaults[type.to_s] || {}).merge(opts)

      if key = @opts[:key]
        unless @opts[:name]
          @opts[:name] = form.namespaced_name(key, @opts[:array] || @opts[:multiple])
          if !@opts.has_key?(:value) && (values = @form.opts[:values])
            set_value_from_namespaced_values(form.namespaces, values, key)
          end
        end
        unless @opts[:id]
          @opts[:id] = form.namespaced_id(key)
          if suffix = @opts[:key_id]
            @opts[:id] << '_' << suffix.to_s
          end
        end
      end
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
      form.serialize(self)
    end

    # Transform the receiver into a lower level +Tag+ form (or an array
    # of them).
    def format
      form.format(self)
    end

    private

    # Set the values option based on the (possibly nested) values
    # hash given, array of namespaces, and key.
    def set_value_from_namespaced_values(namespaces, values, key)
      namespaces.each do |ns|
        v = values[ns] || values[ns.to_s]
        return unless v
        values = v
      end

      @opts[:value] = values.fetch(key){values.fetch(key.to_s){return}}
    end
  end

  # Low level abstract tag form, where each instance represents a
  # html tag with attributes and children.
  class Tag
    # The +Form+ object related to the receiver.
    attr_reader :form

    # The type of tag, should be a symbol (e.g. :input, :select).
    attr_reader :type
    
    # The attributes hash of this receiver.
    attr_reader :attr

    # An array instance representing the children of the receiver,
    # or possibly +nil+ if the receiver has no children.
    attr_reader :children

    # Set the +form+, +type+, +attr+, and +children+.
    def initialize(form, type, attr={}, children=nil)
      @form, @type, @attr = form, type, (attr||{})
      @children = parse_children(children)
    end

    # Adds a child to the array of receiver's children.
    def <<(child)
      if children
        children << child
      else
        @children = [child]
      end
    end

    # Create a new +Tag+ instance with the given arguments and block
    # related to the receiver's +form+.
    def tag(*a, &block)
      form._tag(*a, &block)
    end

    # Return a string containing the serialized content of the receiver.
    def to_s
      form.serialize(self)
    end

    private

    # Convert children constructor argument into the children to use for the tag.
    def parse_children(children)
      case children
      when Array
        children
      when Proc, Method
        parse_children(children.call(self))
      when nil
        nil
      else
        [children]
      end
    end
  end

  # Module that can extend objects associating them with a specific
  # +Form+ instance.  Calling +to_s+ on the object will then use the
  # form's serializer to return a string.
  module Serialized
    # The +Form+ instance related to the receiver.
    attr_accessor :_form

    # Return a string containing the serialized content of the receiver.
    def to_s
      _form.serialize(self)
    end
  end

  # Empty module for marking objects as "raw", where they will no longer
  # html escaped by the default serializer.
  module Raw
  end

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

    # Use a date input by default.  If the :as=>:select option is given,
    # use a multiple select box for the options.
    def format_date
      if @opts[:as] == :select
        name = @attr[:name]
        id = @attr[:id]
        v = @attr[:value]
        if v
          v = Date.parse(v) unless v.is_a?(Date)
          values = {}
          values[:year], values[:month], values[:day] = v.year, v.month, v.day
        end
        ops = {:year=>1900..2050, :month=>1..12, :day=>1..31}
        input.merge_opts(:label_for=>"#{id}_year")
        [:year, '-', :month, '-', :day].map{|x| x.is_a?(String) ? x : form._input(:select, @opts.merge(:label=>nil, :wrapper=>nil, :error=>nil, :name=>"#{name}[#{x}]", :id=>"#{id}_#{x}", :value=>values[x], :options=>ops[x].map{|x| [sprintf("%02i", x), x]})).format}
      else
        _format_input(:date)
      end
    end

    # Use a datetime input by default.  If the :as=>:select option is given,
    # use a multiple select box for the options.
    def format_datetime
      if @opts[:as] == :select
        name = @attr[:name]
        id = @attr[:id]
        v = @attr[:value]
        v = DateTime.parse(v) unless v.is_a?(Time) || v.is_a?(DateTime)
        values = {}
        values[:year], values[:month], values[:day], values[:hour], values[:minute], values[:second] = v.year, v.month, v.day, v.hour, v.min, v.sec
        ops = {:year=>1900..2050, :month=>1..12, :day=>1..31, :hour=>0..23, :minute=>0..59, :second=>0..59}
        input.merge_opts(:label_for=>"#{id}_year")
        [:year, '-', :month, '-', :day, ' ', :hour, ':', :minute, ':', :second].map{|x| x.is_a?(String) ? x : form._input(:select, @opts.merge(:label=>nil, :wrapper=>nil, :error=>nil, :name=>"#{name}[#{x}]", :id=>"#{id}_#{x}", :value=>values[x], :options=>ops[x].map{|x| [sprintf("%02i", x), x]})).format}
      else
        _format_input(:datetime)
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
      if os = process_select_options(@opts[:options])
        @attr[:multiple] = :multiple if @opts[:multiple]

        os = os.map do |label, value, sel, attrs|
          if value || sel
            attrs = attrs.dup
            attrs[:value] = value if value
            attrs[:selected] = :selected if sel
          end
          tag(:option, attrs, [label])
        end
      end
      tag(:select, @attr, os)
    end

    def format_checkboxset
      @opts[:multiple] = true unless @opts.has_key?(:multiple)
      _format_set(:checkbox, :no_hidden=>true, :multiple=>true)
    end

    def format_radioset
      _format_set(:radio)
    end

    def _format_set(type, tag_attrs={})
      raise Error, "can't have radioset with no options" unless os = @opts[:options]
      key = @opts[:key]
      name = @opts[:name]
      if @opts[:error]
        @opts[:set_error] = @opts.delete(:error)
      end
      if @opts[:label]
        @opts[:set_label] = @opts.delete(:label)
      end
      tag_wrapper = @opts.delete(:tag_wrapper) || :default
      wrapper = form.transformer(:wrapper, @opts)

      tags = process_select_options(os).map do |label, value, sel, attrs|
        value ||= label
        r_opts = attrs.merge(tag_attrs).merge(:label=>label||value, :label_attr=>{:class=>:option}, :wrapper=>tag_wrapper)
        r_opts[:value] ||= value if value
        r_opts[:checked] ||= :checked if sel

        if key
          r_opts[:key] ||= key
          r_opts[:key_id] ||= value
        else
          r_opts[:name] ||= name
        end

        form._input(type, r_opts)
      end

      tags.last.opts[:error] = @opts[:set_error]
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

    # Normalize the options used for all input types.  Handles:
    # :required :: Sets the +required+ attribute on the resulting tag if true.
    # :disabled :: Sets the +disabled+ attribute on the resulting tag if true.
    def normalize_options
      copy_options_to_attributes(ATTRIBUTE_OPTIONS)
      copy_boolean_options_to_attributes(ATTRIBUTE_BOOLEAN_OPTIONS)

      Forme.attr_classes(@attr, @opts[:class]) if @opts.has_key?(:class)
      Forme.attr_classes(@attr, 'error') if @opts[:error]

      if data = opts[:data]
        data.each do |k, v|
          sym = :"data-#{k}"
          @attr[sym] = v unless @attr.has_key?(sym)
        end
      end
    end

    # Returns an array of arrays, where each array entry contains the label, value,
    # currently selected flag, and attributes for that tag.
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

        os = os.map do |x|
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

          [text, val, val ? cmp.call(val) : cmp.call(text), attr]
        end

        if prompt = @opts[:add_blank]
          unless prompt.is_a?(String)
            prompt = Forme.default_add_blank_prompt
          end
          os.unshift([prompt, '', false, {}])
        end

        os
      end
    end

    # Create a +Tag+ instance related to the receiver's +form+ with the given
    # arguments.
    def tag(type, attr=@attr, children=nil)
      form._tag(type, attr, children)
    end
    
    # Wrap the tag with the form's +wrapper+.
    def wrap_tag(tag)
      form.transform(:wrapper, @opts, tag, input)
    end

    # Wrap the tag with the form's +error_handler+.
    def wrap_tag_with_error(tag)
      form.transform(:error_handler, @opts, tag, input)
    end

    # Wrap the tag with the form's +labeler+.
    def wrap_tag_with_label(tag)
      form.transform(:labeler, @opts, tag, input)
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
      children = [t.children.select{|o| o.attr[:selected]}.map{|o| o.children}.join(', ')] if t.children
      tag(:span, {}, children)
    end

    # Use a span with text instead of a text area.
    def format_textarea
      tag(:span, {}, @attr[:value])
    end
  end

  # Default error handler used by the library, using an "error" class
  # for the input field and a span tag with an "error_message" class
  # for the error message.
  #
  # Registered as :default.
  class ErrorHandler
    Forme.register_transformer(:error_handler, :default, new)

    # Return tag with error message span tag after it.
    def call(tag, input)
      [tag, input.tag(:span, {:class=>'error_message'}, input.opts[:error])]
    end
  end

  # Default labeler used by the library, using implicit labels (where the
  # label tag encloses the other tag).
  #
  # Registered as :default.
  class Labeler
    Forme.register_transformer(:labeler, :default, new)

    # Return a label tag wrapping the given tag.  For radio and checkbox
    # inputs, the label occurs directly after the tag, for all other types,
    # the label occurs before the tag.
    def call(tag, input)
      label = input.opts[:label]
      label_position = input.opts[:label_position]
      if [:radio, :checkbox].include?(input.type)
        if input.type == :checkbox && tag.is_a?(Array) && tag.length == 2 && tag.first.attr[:type].to_s == 'hidden' 
          t = if label_position == :before
            [label, ' ', tag.last]
          else
            [tag.last, ' ', label]
          end
          return [tag.first , input.tag(:label, input.opts[:label_attr]||{}, t)]
        elsif label_position == :before
          t = [label, ' ', tag]
        else
          t = [tag, ' ', label]
        end
      elsif label_position == :after
        t = [tag, ' ', label]
      else
        t = [label, ": ", tag]
      end
      input.tag(:label, input.opts[:label_attr]||{}, t)
    end
  end

  # Explicit labeler that creates a separate label tag that references
  # the given tag's id using a +for+ attribute.  Requires that all tags
  # with labels have +id+ fields.
  #
  # Registered as :explicit.
  class Labeler::Explicit
    Forme.register_transformer(:labeler, :explicit, new)

    # Return an array with a label tag as the first entry and +tag+ as
    # a second entry.  If the +input+ has a :label_for option, use that,
    # otherwise use the input's :id option.  If neither the :id or
    # :label_for option is used, the label created will not be
    # associated with an input.
    def call(tag, input)
      if [:radio, :checkbox].include?(input.type)
        t = [tag, input.tag(:label, {:for=>input.opts.fetch(:label_for, input.opts[:id])}.merge(input.opts[:label_attr]||{}), [input.opts[:label]])]
        p = :before
      else
        t = [input.tag(:label, {:for=>input.opts.fetch(:label_for, input.opts[:id])}.merge(input.opts[:label_attr]||{}), [input.opts[:label]]), tag]
        p = :after
      end
      if input.opts[:label_position] == p
        t.reverse
      else
        t
      end
    end
  end

  Forme.register_transformer(:wrapper, :default){|tag, input| tag}
  [:li, :p, :div, :span].each do |x|
    Forme.register_transformer(:wrapper, x){|tag, input| input.tag(x, input.opts[:wrapper_attr], Array(tag))}
  end
  Forme.register_transformer(:wrapper, :trtd) do |tag, input|
    a = Array(tag).flatten
    labels, other = a.partition{|e| e.is_a?(Tag) && e.type.to_s == 'label'}
    if labels.length == 1
      ltd = labels
      rtd = other
    elsif a.length == 1
      ltd = [a.first]
      rtd = a[1..-1]
    else
      ltd = a
    end
    input.tag(:tr, input.opts[:wrapper_attr], [input.tag(:td, {}, ltd), input.tag(:td, {}, rtd)])
  end

  # Default inputs_wrapper used by the library, uses a fieldset.
  #
  # Registered as :default.
  class InputsWrapper
    Forme.register_transformer(:inputs_wrapper, :default, new)

    # Wrap the inputs in a fieldset.  If the :legend
    # option is given, add a +legend+ tag as the first
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

  # Use a fieldset and an ol tag to wrap the inputs.
  #
  # Registered as :fieldset_ol.
  class InputsWrapper::FieldSetOL < InputsWrapper
    Forme.register_transformer(:inputs_wrapper, :fieldset_ol, new)

    # Wrap the inputs in an ol tag
    def call(form, opts)
      super(form, opts){form.tag_(:ol){yield}}
    end
  end

  # Use an ol tag to wrap the inputs.
  #
  # Registered as :ol.
  class InputsWrapper::OL
    Forme.register_transformer(:inputs_wrapper, :ol, new)

    # Wrap the inputs in an ol tag
    def call(form, opts, &block)
      form.tag(:ol, &block)
    end
  end

  # Use a div tag to wrap the inputs.
  #
  # Registered as :div.
  class InputsWrapper::Div
    Forme.register_transformer(:inputs_wrapper, :div, new)

    # Wrap the inputs in an ol tag
    def call(form, opts, &block)
      form.tag(:div, &block)
    end
  end

  # Use a table tag to wrap the inputs.
  #
  # Registered as :table.
  class InputsWrapper::Table
    Forme.register_transformer(:inputs_wrapper, :table, new)

    # Wrap the inputs in a table tag.
    def call(form, opts, &block)
      form.tag(:table, &block)
    end
  end

  # Default serializer class used by the library.  Any other serializer
  # classes that want to produce html should probably subclass this class.
  #
  # Registered as :default.
  class Serializer
    Forme.register_transformer(:serializer, :default, new)

    # Borrowed from Rack::Utils, map of single character strings to html escaped versions.
    ESCAPE_HTML = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "'" => "&#39;", '"' => "&quot;"}

    # A regexp that matches all html characters requiring escaping.
    ESCAPE_HTML_PATTERN = Regexp.union(*ESCAPE_HTML.keys)

    # Which tags are self closing (such tags ignore children).
    SELF_CLOSING = [:img, :input]

    # Serialize the tag object to an html string.  Supports +Tag+ instances,
    # +Input+ instances (recursing into +call+ with the result of formatting the input),
    # arrays (recurses into +call+ for each entry and joins the result), and
    # (html escapes the string version of them, unless they include the +Raw+
    # module, in which case no escaping is done).
    def call(tag)
      case tag
      when Tag
        if SELF_CLOSING.include?(tag.type)
          "<#{tag.type}#{attr_html(tag.attr)}/>"
        else
          "#{serialize_open(tag)}#{call(tag.children)}#{serialize_close(tag)}"
        end
      when Input
        call(tag.format)
      when Array
        tag.map{|x| call(x)}.join
      when DateTime, Time
        format_time(tag)
      when Date
        format_date(tag)
      when BigDecimal
        tag.to_s('F')
      when Raw
        tag.to_s
      else
        h tag
      end
    end

    # Returns the opening part of the given tag.
    def serialize_open(tag)
      "<#{tag.type}#{attr_html(tag.attr)}>"
    end

    # Returns the closing part of the given tag.
    def serialize_close(tag)
      "</#{tag.type}>"
    end

    private

    # Return a string in ISO format representing the +Date+ instance.
    def format_date(date)
      date.strftime("%F")
    end

    # Return a string in ISO format representing the +Time+ or +DateTime+ instance.
    def format_time(time)
      time.strftime("%F %H:%M:%S%Z")
    end

    # Escape ampersands, brackets and quotes to their HTML/XML entities.
    def h(string)
      string.to_s.gsub(ESCAPE_HTML_PATTERN){|c| ESCAPE_HTML[c] }
    end

    # Join attribute values that are arrays with spaces instead of an empty
    # string.
    def attr_value(v)
      if v.is_a?(Array)
        v.map{|c| attr_value(c)}.join(' ')
      else
        call(v)
      end
    end

    # Transforms the +tag+'s attributes into an html string, sorting by the keys
    # and quoting and html escaping the values.
    def attr_html(attr)
      attr = attr.to_a.reject{|k,v| v.nil?}
      " #{attr.map{|k, v| "#{k}=\"#{attr_value(v)}\""}.sort.join(' ')}" unless attr.empty?
    end
  end

  # Overrides formatting of dates and times to use an American format without
  # timezones.
  class Serializer::AmericanTime < Serializer
    Forme.register_transformer(:serializer, :html_usa, new)

    def call(tag)
      case tag
      when Tag
        if tag.type.to_s == 'input' && %w'date datetime'.include?((tag.attr[:type] || tag.attr['type']).to_s)
          attr = tag.attr.dup
          attr.delete(:type)
          attr.delete('type')
          attr['type'] = 'text'
          "<#{tag.type}#{attr_html(attr)}/>"
        else
          super
        end
      else
        super
      end
    end

    private

    # Return a string in American format representing the +Date+ instance.
    def format_date(date)
      date.strftime("%m/%d/%Y")
    end

    # Return a string in American format representing the +Time+ or +DateTime+ instance, without the timezone.
    def format_time(time)
      time.strftime("%m/%d/%Y %I:%M:%S%p")
    end
  end

  # Serializer class that converts tags to plain text strings.
  #
  # Registered at :text.
  class Serializer::PlainText
    Forme.register_transformer(:serializer, :text, new)

    # Serialize the tag to plain text string.
    def call(tag)
      case tag
      when Tag
        case tag.type.to_sym
        when :input
          case tag.attr[:type].to_sym
          when :radio, :checkbox
            tag.attr[:checked] ? '_X_' : '___'
          when :submit, :reset, :hidden
            ''
          when :password
            "********\n"
          else
            "#{tag.attr[:value].to_s}\n"
          end
        when :select
          "\n#{call(tag.children)}"
        when :option
          "#{call([tag.attr[:selected] ? '_X_ ' : '___ ', tag.children])}\n"
        when :textarea, :label
          "#{call(tag.children)}\n"
        when :legend
          v = call(tag.children)
          "#{v}\n#{'-' * v.length}\n"
        else
          call(tag.children)
        end
      when Input
        call(tag.format)
      when Array
        tag.map{|x| call(x)}.join
      else
        tag.to_s
      end
    end
  end
end
