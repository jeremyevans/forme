require 'forme/version'

# Forme is designed to make creating forms easier.  Flexibility and
# simplicity are primary objectives.  The basic usage involves creating
# a <tt>Forme::Form</tt> instance, and calling +input+ and +tag+ methods
# to return html strings for widgets, but it could also be used for
# serializing to other formats, or even as a DSL for a GUI application.
#
# In order to be flexible, Forme stores tags in abstract form until
# output is requested.  There are two separate abstract forms that Forme
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
#   Forme::Input.new(:select, :options=>[['foo', 1]])
#   # or
#   Forme::Tag.new(:select, {}, [Forme.Tag.new(:option, {:value=>1}, ['foo'])])
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
# Technically, only the +Formatter+ and +Serializer+ are necessary,
# as it is up to the +Formatter+ to call the +Labeler+ and/or +ErrorHandler+ (if necessary) and
# the +Wrapper+.
# 
# There is also an +InputsWrapper+ transformer, that is called by
# <tt>Forme::Form#inputs</tt>.  It's used to wrap up a group of
# related options (in a fieldset by default).
#
# The <tt>Forme::Form</tt> object takes the 4 processors as options (:formatter,
# :labeler, :wrapper, and :serializer), all of which should be objects responding
# to +call+ (so you can use procs) or be symbols registered with the library.
module Forme
  # Exception class for exceptions raised by Forme.
  class Error < StandardError
  end

  TRANSFORMERS = {:formatter=>{}, :serializer=>{}, :wrapper=>{}, :error_handler=>{}, :labeler=>{}, :inputs_wrapper=>{}}

  def self.register_transformer(type, sym, obj=nil, &block)
    raise Error, "Must provide either block or obj, not both" if obj && block
    TRANSFORMERS[type][sym] = obj||block
  end

  # Call <tt>Forme::Form.form</tt> with the given arguments and block.
  def self.form(*a, &block)
    Form.form(*a, &block)
  end

  # The +Form+ class is the main entry point to the library.  
  # Using the +input+ and +tag+ methods, one can easily create
  # html tag strings.
  class Form
    # The object related to this form, if any.  If the +Form+ has an associated
    # obj, then calls to +input+ are assumed to be accessing fields of the object
    # instead to directly representing input types.
    attr_reader :obj

    # A hash of options for the +Form+. Currently, the following are recognized by
    # default (but a customized +formatter+ could use more options):
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

    # Create a +Form+ object and yield it to the block,
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
      t = if obj.is_a?(Hash)
        raise Error, "Can't provide 3 hash arguments to form" unless opts.empty?
        opts = attr
        attr = obj
        new(opts).form(attr, &block)
      else
        new(obj, opts).form(attr, &block)
      end
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

    def transformer(type, trans)
      case trans
      when Symbol
        t = TRANSFORMERS[type][trans] || raise(Error, "invalid #{type}: #{trans.inspect} (valid #{type}s: #{TRANSFORMERS[type].keys.join(', ')})")
        t.is_a?(Class) ? t.new : t
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

    def emit(tag)
    end

    # Creates an +Input+ with the given +field+ and +opts+, and returns
    # a serialized version of the formatted input.
    #
    # If the form is associated with an +obj+, or the :obj key exists in
    # the +opts+ argument, treats the +field+ as a call to the obj.  If the
    # obj responds to +forme_input+, that method is called with the field
    # and a copy of +opts+.  Otherwise, the field is used as a method call
    # on the obj and a text input is created with the result.
    # 
    # If no +obj+ is associated with the form, +field+ represents an input
    # type (e.g. :text, :textarea, :select), and an input is created directly
    # with the field and opts.
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
          _input(:text, :name=>field, :id=>field, :value=>obj.send(field))
        end
      else
        _input(field, opts)
      end
      self << input
      input
    end

    def _input(*a)
      input = Input.new(self, *a)
    end

    # Creates a tag using the +inputs_wrapper+ (a fieldset by default), calls
    # input on each given argument, and yields to the block if it is given.
    # You can use array arguments if you want inputs to be created with specific
    # options:
    #
    #   inputs([:field1, :field2])
    #   inputs([[:field1, {:name=>'foo'}], :field2])
    def inputs(ins=[], opts={})
      transform(:inputs_wrapper, opts, self, opts) do
        ins.each do |i|
          emit(input(*i))
        end
        yield if block_given?
      end
    end

    # Returns a string representing the opening of the form tag.
    # Requires the serializer implements +serialize_open+.
    def open(attr)
      serializer.serialize_open(_tag(:form, attr)) if serializer.respond_to?(:serialize_open)
    end

    # Returns a string representing the closing of the form tag.
    # Requires the serializer implements +serialize_close+.
    def close
      serializer.serialize_close(_tag(:form)) if serializer.respond_to?(:serialize_close)
    end

    def _tag(*a, &block)
      tag = Tag.new(self, *a, &block)
    end

    # Creates a +Tag+ instance with the given arguments, and returns
    # a serialized version of it.
    def tag(*a, &block)
      tag = _tag(*a)
      self << tag
      nest(tag, &block) if block
      tag
    end

    # Creates a :submit +Input+ with the given opts, and returns a serialized
    # version of the formatted input.
    def button(opts={})
      input = _input(:submit, opts)
      self << input
      input
    end

    # Add the input/tag to the innermost nesting tag.
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

    # Add a new nesting level by entering the tag.  Yield
    # while inside the tag, and ensure when the block
    # returns to remove the nesting level.
    def nest(tag)
      @nesting << tag
      yield self
    ensure
      @nesting.pop
    end
  end

  # High level abstract tag form.  Doesn't contain any logic.
  class Input
    # The +Form+ object related to this +Input+.
    attr_reader :form

    # The type of input, should be a symbol (e.g. :submit, :text, :select).
    attr_reader :type

    # The options hash for this +Input+.
    attr_reader :opts

    # Set the +form+, +type+, and +opts+.
    def initialize(form, type, opts={})
      @form, @type, @opts = form, type, opts
    end

    def to_s
      form.serialize(self)
    end

    def format
      form.format(self)
    end
  end

  # Low level abstract tag form.  Doesn't contain any logic.
  class Tag
    # The +Form+ object related to this +Tag+.
    attr_reader :form

    # The type of tag, should be a symbol (e.g. :input, :select).
    attr_reader :type
    
    # The attributes hash of this +Tag+.
    attr_reader :attr

    # Any children of this +Tag+, should be an array of +Tag+ objects
    # or strings (representing text nodes).
    attr_reader :children

    # Set the +form+, +type+, +attr+, and +children+.
    def initialize(form, type, attr={}, children=[])
      children = TagArray.new(form, children) if children.is_a?(Array)
      @form, @type, @attr, @children = form, type, attr, children
    end

    # Adds a child to the list of receiver's children.
    def <<(child)
      children << child
    end

    def tag(*a, &block)
      form._tag(*a, &block)
    end

    def to_s
      form.serialize(self)
    end
  end

  class TagArray < Array
    attr_accessor :form

    def self.new(form, contents)
      a = super(contents)
      a.form = form
      a
    end

    def tag(*a, &block)
      form._tag(*a, &block)
    end
  end

  # Empty module for marking objects as "raw", where they will no longer
  # html escaped by the default serializer.
  module Raw
  end

  # Base (empty) class for formatters supported by the library.
  class Formatter
  end

  # The default formatter used by the library.  Any custom formatters should
  # probably inherit from this formatter unless they have very special needs.
  class Formatter::Default < Formatter
    Forme.register_transformer(:formatter, :default, self)

    attr_reader :input
    attr_reader :form
    attr_reader :attr
    attr_reader :opts

    # Used to specify the value of the hidden input created for checkboxes.
    # Since the default for an unspecified checkbox value is 1, the default is
    # 0. If the checkbox value is 't', the hidden value is 'f', since that is
    # common usage for boolean values.
    CHECKBOX_MAP = Hash.new(0)
    CHECKBOX_MAP['t'] = 'f'

    # Transform the +input+ into a +Tag+ instance, wrapping it with the +form+'s
    # wrapper, and the form's +error_handler+ and +labeler+ if the input has an
    # error or a label.
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

    # Convert the +Input+ to a +Tag+.
    def convert_to_tag(type)
      meth = :"format_#{type}"
      if respond_to?(meth, true)
        send(meth)
      else
        format_input(type)
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

    # The default fallback method for handling inputs.  Assumes an input tag
    # with the type attribute set the the type of the input.
    def format_input(type)
      @attr[:type] = type
      tag(:input)
    end

    # Takes a select input and turns it into a select tag with (possibly) option
    # children tags.  Respects the following options:
    # :options :: an array of options.  Processes each entry.  If that entry is
    #             an array, takes the first entry in the hash as the text child
    #             of the option, and the last entry as the value of the option.
    #             if not set, ignores the remaining options.
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

    def handle_array(tag)
      (tag.is_a?(Array) && !tag.is_a?(TagArray)) ? TagArray.new(form, tag) : tag
    end

    # Normalize the options used for all input types.
    def normalize_options
      @attr[:required] = :required if @attr.delete(:required)
      @attr[:disabled] = :disabled if @attr.delete(:disabled)
      @opts[:label] = @attr.delete(:label)
      @opts[:error] = @attr.delete(:error)
      @opts[:wrapper] = @attr.delete(:wrapper) if @attr.has_key?(:wrapper)
      @opts[:error_handler] = @attr.delete(:error_handler) if @attr.has_key?(:error_handler)
      @opts[:labeler] = @attr.delete(:labeler) if @attr.has_key?(:labeler)
      @attr.delete(:formatter)
    end

    def tag(type, attr=@attr, children=[])
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

  # Formatter that disables all input fields
  class Formatter::Disabled < Formatter::Default
    Forme.register_transformer(:formatter, :disabled, self)

    private

    def normalize_options
      if @attr.delete(:disabled) == false
        super
      else
        super
        @attr[:disabled] = :disabled
      end
    end
  end

  # Formatter that uses text spans for most input types,
  # and disables radio/checkbox inputs.
  class Formatter::ReadOnly < Formatter::Default
    Forme.register_transformer(:formatter, :readonly, self)

    private

    # Disabled checkbox inputs.
    def format_checkbox
      @attr[:disabled] = :disabled
      super
    end

    # Use a span with plain text instead of an input field.
    def format_input(type)
      tag(:span, {}, @attr[:value])
    end

    # Disabled radio button inputs.
    def format_radio
      @attr[:disabled] = :disabled
      super
    end

    # Use a span with plain text of the selected value instead of a select box.
    def format_select
      tag(:span, {}, [super.children.select{|o| o.attr[:selected]}.map{|o| o.children}.join(', ')])
    end

    def format_textarea
      tag(:span, {}, @attr[:value])
    end
  end

  # Base (empty) class for error handlers supported by the library. 
  class ErrorHandler
  end

  # Default error handler used by the library, using an "error" class
  # for the input field and a span tag with an "error_message" class
  # for the error message.
  class ErrorHandler::Default < ErrorHandler
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

  # Base (empty) class for labelers supported by the library. 
  class Labeler
  end

  # Default labeler used by the library, using implicit labels (where the
  # label tag encloses the other tag).
  class Labeler::Default < Labeler
    Forme.register_transformer(:labeler, :default, new)

    # Return a label tag wrapping the given tag.
    def call(label, tag)
      t = if tag.is_a?(Tag) && tag.type == :input && [:radio, :checkbox].include?(tag.attr[:type])
        [tag, " #{label}"]
      else
        ["#{label}: ", tag]
      end
      tag.tag(:label, {}, t)
    end
  end

  # Explicit labelers that creates a separate label tag that references
  # the given tag's id using a +for+ attribute.  Requires that all tags
  # with labels have +id+ fields.
  class Labeler::Explicit < Labeler
    Forme.register_transformer(:labeler, :explicit, new)

    # Return an array with a label tag as the first entry and the given
    # tag as the second.
    def call(label, tag)
      t = tag.is_a?(Tag) ? tag : tag.find{|tg| tg.is_a?(Tag) && tg.attr[:type] != :hidden}
      id = t.attr[:id]
      raise Error, "Explicit labels require an id field" unless id
      [tag.tag(:label, {:for=>id}, [label]), tag]
    end
  end

  Forme.register_transformer(:wrapper, :default){|tag| tag}
  Forme.register_transformer(:wrapper, :li){|tag| tag.tag(:li, {}, Array(tag))}
  Forme.register_transformer(:wrapper, :trtd){|tag| tag.tag(:tr, {}, Array(tag).map{|t| tag.tag(:td, {}, [t])})}

  # Base (empty) class for inputs wrappers supported by the library.
  class InputsWrapper
  end

  # Default inputs_wrapper class used by the library, uses a fieldset.
  class InputsWrapper::Default < InputsWrapper
    Forme.register_transformer(:inputs_wrapper, :default, new)

    # Wrap the inputs in a fieldset
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

  # Use an ol tag to wrap the inputs
  class InputsWrapper::OL < InputsWrapper
    Forme.register_transformer(:inputs_wrapper, :ol, new)

    # Wrap the inputs in an ol tag
    def call(form, opts, &block)
      form.tag(:ol, &block)
    end
  end

  # Use a table tag to wrap the inputs
  class InputsWrapper::Table < InputsWrapper
    Forme.register_transformer(:inputs_wrapper, :table, new)

    # Wrap the inputs in a table tag
    def call(form, opts, &block)
      form.tag(:table, &block)
    end
  end

  # Base (empty) class for serializers supported by the library.
  class Serializer
  end

  # Default serializer class used by the library.  Any other serializer
  # classes that want to produce html should probably subclass this class.
  class Serializer::Default < Serializer
    Forme.register_transformer(:serializer, :default, new)

    # Borrowed from Rack::Utils, map of single character strings to html escaped versions.
    ESCAPE_HTML = {
      "&" => "&amp;",
      "<" => "&lt;",
      ">" => "&gt;",
      "'" => "&#39;",
      '"' => "&quot;",
    }

    # A regexp that matches all html characters requiring escaping.
    ESCAPE_HTML_PATTERN = Regexp.union(*ESCAPE_HTML.keys)

    # Which tags are self closing (such tags ignore children).
    SELF_CLOSING = [:img, :input]

    # Serialize the tag object to an html string.  Supports +Tag+ instances,
    # arrays (recurses into +call+ for each entry and joins the result), and
    # strings (html escapes them).
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
      when Array, TagArray
        tag.map{|x| call(x)}.join
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

    # Escape ampersands, brackets and quotes to their HTML/XML entities.
    def h(string)
      string.to_s.gsub(ESCAPE_HTML_PATTERN){|c| ESCAPE_HTML[c] }
    end

    # Transforms the +tag+'s attributes into an html string, sorting by the keys
    # and quoting and html escaping the values.
    def attr_html(tag)
      " #{tag.attr.sort_by{|k,v| k.to_s}.reject{|k,v| v.nil?}.map{|k, v| "#{k}=\"#{h v}\""}.join(' ')}" unless tag.attr.empty?
    end
  end


  # Serializer class that converts tags to plain text strings.
  class Serializer::PlainText < Serializer
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
        else
        end
      when Input
        call(tag.format)
      when Array, TagArray
        tag.map{|x| call(x)}.join
      else
        tag
      end
    end
  end
end
