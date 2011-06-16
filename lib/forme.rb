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
# 1. +Formatter+: converts a <tt>Forme::Input</tt> instance into a
#    <tt>Forme::Tag</tt> instance (or array of them).
# 2. +ErrorHandler+: If the <tt>Forme::Input</tt> instance has a error,
#    takes the formatted tag and marks it as having the error.
# 2. +Labeler+: If the <tt>Forme::Input</tt> instance has a label,
#    takes the formatted output and labels it.
# 3. +Wrapper+: Takes the output of the labeler (or formatter if
#    no label), and wraps it in another tag (or just returns it
#    directly).
# 4. +Serializer+: converts a <tt>Forme::Tag</tt> instance into a
#    string.
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

  # Main hash storing the registered transformers.  Maps transformer type symbols to subhashes
  # containing the registered transformers for that type.  Those subhashes should have symbol
  # keys and values that are either classes or objects that respond to +call+.
  TRANSFORMERS = {:formatter=>{}, :serializer=>{}, :wrapper=>{}, :error_handler=>{}, :labeler=>{}, :inputs_wrapper=>{}}

  # Register a new transformer with this library. Arguments:
  # +type+ :: Transformer type symbol
  # +sym+ :: Transformer name symbol
  # <tt>obj/block</tt> :: Transformer to associate with this symbol.  Should provide either
  #                       +obj+ or +block+, but not both.  If +obj+ is given, should be
  #                       either a +Class+ instance or it should respond to +call+.  If a
  #                       +Class+ instance is given, instances of that class should respond
  #                       to +call+, and the a new instance of that class should be used
  #                       for each transformation.
  def self.register_transformer(type, sym, obj=nil, &block)
    raise Error, "Not a valid transformer type" unless TRANSFORMERS.has_key?(type)
    raise Error, "Must provide either block or obj, not both" if obj && block
    TRANSFORMERS[type][sym] = obj||block
  end

  # Call <tt>Forme::Form.form</tt> with the given arguments and block.
  def self.form(*a, &block)
    Form.form(*a, &block)
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

    # A hash of options for the receiver. Currently, the following are recognized by
    # default:
    # :obj :: Sets the +obj+ attribute
    # :error_handler :: Sets the +error_handler+ for the form
    # :formatter :: Sets the +formatter+ for the form
    # :inputs_wrapper :: Sets the +inputs_wrapper+ for the form
    # :labeler :: Sets the +labeler+ for the form
    # :wrapper :: Sets the +wrapper+ for the form
    # :serializer :: Sets the +serializer+ for the form
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

    # The +inputs_wrapper+ determines how calls to +inputs+ are wrapped.  Must
    # respond to +call+ or be a registered symbol.
    attr_reader :inputs_wrapper

    # The +serializer+ determines how +Tag+ objects are transformed into strings.
    # Must respond to +call+ or be a registered symbol.
    attr_reader :serializer

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
          form.inputs(ins, opts) if ins
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
      if @obj && @obj.respond_to?(:forme_config)
        @obj.forme_config(self)
      end
      TRANSFORMERS.keys.each do |k|
        instance_variable_set(:"@#{k}", transformer(k, @opts.fetch(k, :default)))
      end
      @nesting = []
    end

    # If there is a related transformer, call it with the given +args+ and +block+.
    # Otherwise, attempt to return the initial input without modifying it.
    def transform(type, trans, *args, &block)
      if trans = transformer(type, trans)
        trans.call(*args, &block)
      else
        case type
        when :inputs_wrapper
          yield
        when :labeler, :error_handler
          args[1]
        else
          args[0]
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
      tag(:form, attr, &block)
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
    def inputs(inputs=[], opts={})
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

    private

    # Make the given tag the currently open tag, and yield.  After the
    # block returns, make the previously open tag the currently open
    # tag.
    def nest(tag)
      @nesting << tag
      yield self
    ensure
      @nesting.pop
    end
  end

  # High level abstract tag form, transformed by formatters into the lower
  # level +Tag+ form (or a +TagArray+ of them).
  class Input
    # The +Form+ object related to the receiver.
    attr_reader :form

    # The type of input, should be a symbol (e.g. :submit, :text, :select).
    attr_reader :type

    # The options hash for the receiver.
    attr_reader :opts

    # Set the +form+, +type+, and +opts+.
    def initialize(form, type, opts={})
      @form, @type, @opts = form, type, opts
    end

    # Return a string containing the serialized content of the receiver.
    def to_s
      form.serialize(self)
    end

    # Transform the receiver into a lower level +Tag+ form (or a +TagArray+
    # of them).
    def format
      form.format(self)
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

    # A +TagArray+ instance representing the children of the receiver,
    # or possibly +nil+ if the receiver has no children.
    attr_reader :children

    # Set the +form+, +type+, +attr+, and +children+.
    def initialize(form, type, attr={}, children=nil)
      case children
      when TagArray
        @children = children
      when Array
        @children = TagArray.new(form, children)
      when nil
        @children = nil
      else
        @children = TagArray.new(form, [children])
      end
      @form, @type, @attr = form, type, attr
    end

    # Adds a child to the array of receiver's children.
    def <<(child)
      if children
        children << child
      else
        @children = TagArray.new(form, [child])
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
  end

  # Array subclass related to a specific +Form+ instance.
  class TagArray < Array
    # The +Form+ instance related to the receiver.
    attr_accessor :form

    # Create a new instance using +contents+, associated to
    # the given +form+.
    def self.new(form, contents)
      a = super(contents)
      a.form = form
      a
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

    # Create a new instance and call it
    def self.call(input)
      new.call(input)
    end

    # The +Form+ instance for the receiver, taken from the +input+.
    attr_reader :form
    
    # The +Input+ instance for the receiver.  This is what the receiver
    # converts to the lower level +Tag+ form (or a +TagArray+ of them). 
    attr_reader :input
    
    # The attributes to to set on the lower level +Tag+ form returned.
    # This are derived from the +input+'s +opts+, but some processing is done on
    # them.
    attr_reader :attr
    
    # The options hash related to this formatter's processing, derived
    # from the +input+'s +opts+.  Keys used:
    # :error :: An error message for the +input+
    # :error_handler :: A custom +error_handler+ to use, instead of the +form+'s default
    # :label :: A label for the +input+
    # :labeler :: A custom +labeler+ to use, instead of the +form+'s default
    # :wrapper :: A custom +wrapper+ to use, instead of the +form+'s default
    attr_reader :opts

    # Used to specify the value of the hidden input created for checkboxes.
    # Since the default for an unspecified checkbox value is 1, the default is
    # 0. If the checkbox value is 't', the hidden value is 'f', since that is
    # common usage for boolean values.
    CHECKBOX_MAP = Hash.new(0)
    CHECKBOX_MAP['t'] = 'f'

    # Transform the +input+ into a +Tag+ instance (or +TagArray+ of them),
    # wrapping it with the +form+'s wrapper, and the form's +error_handler+
    # and +labeler+ if the +input+ has an <tt>:error</tt> or <tt>:label</tt>
    # options.
    def call(input)
      @input = input
      @form = input.form
      @attr = input.opts.dup
      @opts = {}
      normalize_options

      tag = handle_array(convert_to_tag(input.type))

      if error = @opts[:error]
        tag = handle_array(wrap_tag_with_error(error, tag))
      end
      if label = @opts[:label]
        tag = handle_array(wrap_tag_with_label(label, tag))
      end

      handle_array(wrap_tag(tag))
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
    # input tag.  Recognizes the following options:
    # :checked :: checkbox is set to checked if so.
    # :hidden_value :: sets the value of the hidden input tag.
    def format_checkbox
      @attr[:type] = :checkbox
      @attr[:checked] = :checked if @attr.delete(:checked)
      if @attr[:name] && !@attr.delete(:no_hidden)
        attr = {:type=>:hidden}
        unless attr[:value] = @attr.delete(:hidden_value)
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
      @attr[:checked] = :checked if @attr.delete(:checked)
      @attr[:type] = :radio
      tag(:input)
    end

    # Use a date input by default.  If the :as=>:select option is given,
    # use a multiple select box for the options.
    def format_date
      if @attr.delete(:as) == :select
        name = @attr[:name]
        id = @attr[:id]
        v = @attr[:value]
        if v
          v = Date.parse(v) unless v.is_a?(Date)
          values = {}
          values[:year], values[:month], values[:day] = v.year, v.month, v.day
        end
        ops = {:year=>1900..2050, :month=>1..12, :day=>1..31}
        [:year, :month, :day].map{|x| form._input(:select, @attr.dup.merge(:label=>nil, :wrapper=>nil, :error=>nil, :name=>"#{name}[#{x}]", :id=>"#{id}_#{x}", :value=>values[x], :options=>ops[x].to_a.map{|x| [x, x]})).format}
      else
        _format_input(:date)
      end
    end

    # The default fallback method for handling inputs.  Assumes an input tag
    # with the type attribute set to input.
    def _format_input(type)
      @attr[:type] = type
      tag(:input)
    end

    # Takes a select input and turns it into a select tag with (possibly) option
    # children tags.  Respects the following options:
    # :options :: an array of options.  Processes each entry.  If that entry is
    #             an array, takes the first entry in the hash as the text child
    #             of the option, and the last entry as the value of the option.
    #             if not set, ignores the remaining options.
    # :add_blank :: Add a blank option if true.  If the value is a string,
    #               use it as the text content of the blank option.  The value of
    #               the blank option is always the empty string.
    # :text_method :: If set, each entry in the array has this option called on
    #                 it to get the text of the object.
    # :value_method :: If set (and :text_method is set), each entry in the array
    #                  has this method called on it to get the value of the option.
    # :selected :: The value that should be selected.  Any options that are equal to
    #              this value (or included in this value if a multiple select box),
    #              are set to selected.
    # :multiple :: Creates a multiple select box.
    # :value :: Same as :selected, but has lower priority.
    def format_select
      if os = @attr.delete(:options)
        vm = @attr.delete(:value_method)
        tm = @attr.delete(:text_method)
        sel = @attr.delete(:selected) || @attr.delete(:value)
        if @attr.delete(:multiple)
          @attr[:multiple] = :multiple
          sel = Array(sel)
          cmp = lambda{|v| sel.include?(v)}
        else
          cmp = lambda{|v| v == sel}
        end
        os = os.map do |x|
          attr = {}
          if tm
            text = x.send(tm)
            if vm
              val = x.send(vm)
              attr[:value] = val
              attr[:selected] = :selected if cmp.call(val)
            else
              attr[:selected] = :selected if cmp.call(text)
            end
            form._tag(:option, attr, [text])
          elsif x.is_a?(Array)
            val = x.last
            if val.is_a?(Hash)
              attr.merge!(val)
              val = attr[:value]
            else
              attr[:value] = val
            end
            attr[:selected] = :selected if attr.has_key?(:value) && cmp.call(val)
            tag(:option, attr, [x.first])
          else
            attr[:selected] = :selected if cmp.call(x)
            tag(:option, attr, [x])
          end
        end
        if prompt = @attr.delete(:add_blank)
          os.unshift(tag(:option, {:value=>''}, prompt.is_a?(String) ? [prompt] : []))
        end
      end
      tag(:select, @attr, os)
    end

    # Formats a textarea.  Respects the following options:
    # :value :: Sets value as the child of the textarea.
    def format_textarea
      if val = @attr.delete(:value)
        tag(:textarea, @attr, [val])
      else
        tag(:textarea)
      end
    end

    # If +tag+ is an +Array+ and not a +TagArray+, turn it into
    # a +TagArray+ related to the receiver's +form+.  Otherwise,
    # return +tag+.
    def handle_array(tag)
      (tag.is_a?(Array) && !tag.is_a?(TagArray)) ? TagArray.new(form, tag) : tag
    end

    # Normalize the options used for all input types.  Handles:
    # :required :: Sets the +required+ attribute on the resulting tag if true.
    # :disabled :: Sets the +disabled+ attribute on the resulting tag if true.
    def normalize_options
      @attr[:required] = :required if @attr.delete(:required)
      @attr[:disabled] = :disabled if @attr.delete(:disabled)
      if @opts[:label] = @attr.delete(:label)
        @opts[:labeler] = @attr.delete(:labeler) if @attr.has_key?(:labeler)
      end
      if @opts[:error] = @attr.delete(:error)
        @opts[:error_handler] = @attr.delete(:error_handler) if @attr.has_key?(:error_handler)
      end
      @opts[:wrapper] = @attr.delete(:wrapper) if @attr.has_key?(:wrapper)
      @attr.delete(:formatter)
    end

    # Create a +Tag+ instance related to the receiver's +form+ with the given
    # arguments.
    def tag(type, attr=@attr, children=nil)
      form._tag(type, attr, children)
    end
    
    # Wrap the tag with the form's +wrapper+.
    def wrap_tag(tag)
      form.transform(:wrapper, @opts, tag)
    end

    # Wrap the tag with the form's +error_handler+.
    def wrap_tag_with_error(error, tag)
      form.transform(:error_handler, @opts, error, tag)
    end

    # Wrap the tag with the form's +labeler+.
    def wrap_tag_with_label(label, tag)
      form.transform(:labeler, @opts, label, tag)
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
      if @attr.delete(:disabled) == false
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

    # Return a label tag wrapping the given tag.
    def call(err_msg, tag)
      msg_tag = tag.tag(:span, {:class=>'error_message'}, err_msg)
      if tag.is_a?(Tag)
        attr = tag.attr
        if attr[:class]
          attr[:class] += ' error'
        else
          attr[:class] = 'error'
        end
      end
      [tag, msg_tag]
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
    def call(label, tag)
      t = if tag.is_a?(Tag) && tag.type == :input && [:radio, :checkbox].include?(tag.attr[:type])
        [tag, " #{label}"]
      else
        ["#{label}: ", tag]
      end
      tag.tag(:label, {}, t)
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
    # a second entry.  If +tag+ is an array, scan it for the first +Tag+
    # instance that isn't hidden (since hidden tags shouldn't have labels). 
    # If the +tag+ doesnt' have an id attribute, an +Error+ is raised.
    def call(label, tag)
      t = tag.is_a?(Tag) ? tag : tag.find{|tg| tg.is_a?(Tag) && tg.attr[:type] != :hidden}
      id = t.attr[:id]
      raise Error, "Explicit labels require an id field" unless id
      [tag.tag(:label, {:for=>id}, [label]), tag]
    end
  end

  Forme.register_transformer(:wrapper, :default){|tag| tag}
  [:li, :p, :div, :span].each do |x|
    Forme.register_transformer(:wrapper, x){|tag| tag.tag(x, {}, Array(tag))}
  end
  Forme.register_transformer(:wrapper, :trtd) do |tag|
    a = Array(tag)
    tag.tag(:tr, {}, a.length == 1 ? tag.tag(:td, {}, a) : [tag.tag(:td, {}, [a.first]), tag.tag(:td, {}, a[1..-1])])
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
      if legend = opts.delete(:legend)
        form.tag(:fieldset) do
          form.emit(form.tag(:legend, {}, legend))
          yield
        end
      else
        form.tag(:fieldset, &Proc.new)
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
      super(form, opts){form.tag(:ol){yield}}
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
          "<#{tag.type}#{attr_html(tag)}/>"
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
      when Raw
        tag.to_s
      else
        h tag
      end
    end

    # Returns the opening part of the given tag.
    def serialize_open(tag)
      "<#{tag.type}#{attr_html(tag)}>"
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

    # Transforms the +tag+'s attributes into an html string, sorting by the keys
    # and quoting and html escaping the values.
    def attr_html(tag)
      attr = tag.attr.to_a.reject{|k,v| v.nil?}
      " #{attr.map{|k, v| "#{k}=\"#{call(v)}\""}.sort.join(' ')}" unless attr.empty?
    end
  end

  # Overrides formatting of dates and times to use an American format without
  # timezones.
  module Serializer::AmericanTime
    Forme.register_transformer(:serializer, :html_usa, Serializer.new.extend(self))

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
