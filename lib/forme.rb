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
# data is broken down to the following steps:
#
# 1. Formatter: converts a <tt>Forme::Input</tt> instance into a
#    <tt>Forme::Tag</tt> instance (or array of them).
# 2. Labeler: If the <tt>Forme::Input</tt> instance has a label,
#    takes the formatted output and labels it.
# 3. Wrapper: Takes the output of the labeler (or formatter if
#    no label), and wraps it in another tag (or just returns it
#    directly).
# 4. Serializer: converts a <tt>Forme::Tag</tt> instance into a
#    string.
#
# Technically, only the +Formatter+ and +Serializer+ are necessary,
# as it is up to the +Formatter+ to call the +Labeler+ (if necessary) and
# the +Wrapper+.
#
# The <tt>Forme::Form</tt> object takes the 4 processors as options (:formatter,
# :labeler, :wrapper, and :serializer), all of which should be objects responding
# to +call+ (so you can use procs) or be symbols registered with the library.
module Forme
  # Exception class for exceptions raised by Forme.
  class Error < StandardError
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
    # :formatter :: Sets the +formatter+ for the form
    # :labeler :: Sets the +labeler+ for the form
    # :wrapper :: Sets the +wrapper+ for the form
    # :serializer :: Sets the +serializer+ for the form
    attr_reader :opts

    # The formatter determines how the +Input+ created are transformed into
    # +Tag+ objects. Must respond to +call+ or be a registered symbol.
    attr_reader :formatter

    # The labeler determines how to label tags.  Must respond to +call+ or be
    # a registered symbol.
    attr_reader :labeler

    # The wrapper determines how (potentially labeled) tags are wrapped.  Must
    # respond to +call+ or be a registered symbol.
    attr_reader :wrapper

    # The serializer determines how +Tag+ objects are transformed into strings.
    # Must respond to +call+ or be a registered symbol.
    attr_reader :serializer

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
      @formatter = find_transformer(Formatter, :formatter)
      @labeler = find_transformer(Labeler, :labeler)
      @serializer = find_transformer(Serializer, :serializer)
      @wrapper = find_transformer(Wrapper, :wrapper)
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
          obj.forme_input(field, opts.dup)
        else
          Input.new(:text, :name=>field, :id=>field, :value=>obj.send(field))
        end
      else
        Input.new(field, opts)
      end
      serialize(format(input))
    end

    # Returns a string representing the opening of the form tag.
    # Requires the serializer implements +serialize_open+.
    def open(attr)
      serializer.serialize_open(Tag.new(:form, attr))
    end

    # Returns a string representing the closing of the form tag.
    # Requires the serializer implements +serialize_close+.
    def close
      serializer.serialize_close(Tag.new(:form))
    end

    # Creates a +Tag+ instance with the given arguments, and returns
    # a serialized version of it.
    def tag(*a)
      serialize(tag!(*a))
    end

    # Creates a +Tag+ instance with the given arguments, and returns it.
    def tag!(*a)
      Tag.new(*a)
    end

    # Creates a :submit +Input+ with the given opts, and returns a serialized
    # version of the formatted input.
    def button(opts={})
      serialize(format(Input.new(:submit, opts)))
    end

    private

    # Looks up the transformer if it is a registered symbol.
    def find_transformer(klass, sym)
      transformer ||= opts.fetch(sym, :default)
      transformer = klass.get_subclass_instance(transformer) if transformer.is_a?(Symbol)
      transformer
    end

    # Formats the +input+ using the +formatter+.
    def format(input)
      formatter.call(self, input)
    end

    # Serializes the +tag+ using the +serializer+.
    def serialize(tag)
      serializer.call(tag)
    end
  end

  # High level abstract tag form.  Doesn't contain any logic.
  class Input
    # The type of input (e.g. :submit, :text, :select).
    attr_reader :type

    # The options for this +Input+.
    attr_reader :opts
    
    # Set the +type+ and +opts+.
    def initialize(type, opts={})
      @type = type
      @opts = opts
    end
  end

  # Low level abstract tag form.  Doesn't contain any logic.
  class Tag
    # The type of tag, should be a symbol (e.g. :input, :select).
    attr_reader :type
    
    # The attributes of the tag, such be a hash.
    attr_reader :attr

    # Any children of the tag, should be an array of +Tag+ objects
    # or strings (representing text nodes).
    attr_reader :children

    # Set the +type+, +attr+, and +children+.
    def initialize(type, attr={}, children=[])
      @type = type
      @attr = attr
      @children = children
    end

    # Adds a child to the list of children for the object.
    def <<(child)
      children << child
    end
  end

  # Helper module for extending classes where subclasses automatically register themselves
  # in a map under a symbol, allowing lookup by symbol name when creating a +Form+.
  module SubclassMap
    # Create the +MAP+ constant hash under the +klass+.
    def self.extended(klass)
      klass.const_set(:MAP, {})
    end

    # Given a +type+ symbol, looks up the symbol in the MAP constant and returns a new
    # instance of it.
    def get_subclass_instance(type)
      subclass = self::MAP[type] || self::MAP[:default]
      raise Error, "invalid #{name.to_s.downcase}: #{type} (valid #{name.to_s.downcase}s: #{klass::MAP.keys.join(', ')})" unless subclass 
      subclass.new
    end

    # Automatically register the subclass in the parent class's MAP.
    def inherited(subclass)
      self::MAP[subclass.name.split('::').last.downcase.to_sym] = subclass
      super
    end
  end

  # Base (empty) class for formatters supported by the library.
  class Formatter
    extend SubclassMap
  end

  # The default formatter used by the library.  Any custom formatters should
  # probably inherit from this formatter unless they have very special needs.
  class Formatter::Default < Formatter
    # Used to specify the value of the hidden input created for checkboxes.
    # Since the default for an unspecified checkbox value is 1, the default is
    # 0. If the checkbox value is 't', the hidden value is 'f', since that is
    # common usage for boolean values.
    CHECKBOX_MAP = Hash.new(0)
    CHECKBOX_MAP['t'] = 'f'

    # Transform the +input+ into a +Tag+ instance.
    def call(form, input)
      opts = input.opts.dup
      l = opts.delete(:label)
      t = input.type
      meth = :"format_#{t}"

      tag = if respond_to?(meth, true)
        send(meth, form, t, opts)
      else
        format_input(form, t, opts)
      end

      tag = form.labeler.call(l, tag) if l

      form.wrapper.call(tag)
    end

    private

    # If the checkbox has a name, will create a hidden input tag with the
    # same name that comes before this checkbox.  That way, if the checkbox
    # is checked, the web app will generally see the value of the checkbox, and
    # if it is not checked, the web app will generally see the value of the hidden
    # input tag.  Recognizes the following options:
    # :checked :: checkbox is set to checked if so.
    # :hidden_value :: sets the value of the hidden input tag.
    def format_checkbox(form, type, opts)
      opts[:type] = type
      opts[:checked] = :checked if opts.delete(:checked)
      if opts[:name]
        attr = {:type=>:hidden}
        unless attr[:value] = opts.delete(:hidden_value)
          attr[:value] = CHECKBOX_MAP[opts[:value]]
        end
        attr[:id] = "#{opts[:id]}_hidden" if opts[:id]
        attr[:name] = opts[:name]
        [Tag.new(:input, attr), Tag.new(:input, opts)]
      else
        Tag.new(:input, opts)
      end
    end

    # For radio buttons, recognizes the :checked option and sets the :checked
    # attribute in the tag appropriately.
    def format_radio(form, type, opts)
      opts[:checked] = :checked if opts.delete(:checked)
      opts[:type] = type
      Tag.new(:input, opts)
    end

    # The default fallback method for handling inputs.  Assumes an input tag
    # with the type attribute set the the type of the input.
    def format_input(form, type, opts)
      opts[:type] = type
      Tag.new(:input, opts)
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
    def format_select(form, type, opts)
      if os = opts.delete(:options)
        vm = opts.delete(:value_method)
        tm = opts.delete(:text_method)
        sel = opts.delete(:selected) || opts.delete(:value)
        if opts.delete(:multiple)
          opts[:multiple] = :multiple
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
            Tag.new(:option, attr, [text])
          elsif x.is_a?(Array)
            val = x.last
            if val.is_a?(Hash)
              attr.merge!(val)
              val = attr[:value]
            else
              attr[:value] = val
            end
            attr[:selected] = :selected if attr.has_key?(:value) && cmp.call(val)
            Tag.new(:option, attr, [x.first])
          else
            attr[:selected] = :selected if cmp.call(x)
            Tag.new(:option, attr, [x])
          end
        end
      end
      Tag.new(type, opts, os)
    end

    # Formats a textarea.  Respects the following options:
    # :value :: Sets value as the child of the textarea.
    def format_textarea(form, type, opts)
      if val = opts.delete(:value)
        Tag.new(type, opts, [val])
      else
        Tag.new(type, opts)
      end
    end
  end

  # Base (empty) class for labelers supported by the library. 
  class Labeler
    extend SubclassMap
  end

  # Default labeler used by the library, using implicit labels (where the
  # label tag encloses the other tag).
  class Labeler::Default < Labeler
    # Return a label tag wrapping the given tag.
    def call(label, tag)
      Tag.new(:label, {}, ["#{label}: ", tag])
    end
  end

  # Explicit labelers that creates a separate label tag that references
  # the given tag's id using a +for+ attribute.  Requires that all tags
  # with labels have +id+ fields.
  class Labeler::Explicit < Labeler
    # Return an array with a label tag as the first entry and the given
    # tag as the second.
    def call(label, tag)
      raise Error, "Explicit labels require an id field" unless id = tag.attr[:id]
      [Tag.new(:label, {:for=>id}, [label]), tag]
    end
  end

  # Base (empty) class for wrappers supported by the library.
  class Wrapper
    extend SubclassMap
  end

  # Default wrapper class used by the library, which doesn't actually wrap.
  class Wrapper::Default < Wrapper
    # Default wrapper doesn't wrap, it just returns the tag as is.
    def call(tag)
      tag
    end
  end

  # Wrapper class which wraps the class in an li tag. 
  class Wrapper::LI < Wrapper
    def call(tag)
      Tag.new(:li, {}, Array(tag))
    end
  end

  # Base (empty) class for serializers supported by the library.
  class Serializer
    extend SubclassMap
  end

  # Default serializer class used by the library.  Any other serializer
  # classes that want to produce html should probably subclass this class.
  class Serializer::Default < Serializer
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
      if tag.is_a?(Tag)
        if SELF_CLOSING.include?(tag.type)
          "<#{tag.type}#{attr_html(tag)}/>"
        else
          "#{serialize_open(tag)}#{call(tag.children)}#{serialize_close(tag)}"
        end
      elsif tag.is_a?(Array)
        tag.map{|x| call(x)}.join
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
      " #{tag.attr.sort_by{|k,v| k.to_s}.map{|k, v| "#{k}=\"#{h v}\""}.join(' ')}" unless tag.attr.empty?
    end
  end
end
