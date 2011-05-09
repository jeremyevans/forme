require 'forme/version'

module Forme
  class Error < StandardError
  end

  class Form
    attr_reader :obj
    attr_reader :opts
    attr_reader :formatter
    attr_reader :serializer
    def initialize(obj=nil, opts={})
      @obj = obj
      @opts = opts
      @formatter = find_transformer(Formatter)
      @serializer = find_transformer(Serializer)
    end

    def input(field, opts={})
      if obj
        if obj.respond_to?(:forme_input)
          obj.forme_input(self, field, opts)
        else
          Input.new(self, :text, :name=>field, :id=>field, :value=>obj.send(field))
        end
      else
        Input.new(self, field, opts)
      end.serialize
    end

    def open(attr)
      serializer.serialize_open(Tag.new(self, :form, attr))
    end

    def close
      serializer.serialize_close(Tag.new(self, :form))
    end

    def tag(type, attr={})
      Tag.new(self, type, attr).serialize
    end

    private

    def find_transformer(klass)
      sym = klass.name.to_s.downcase.to_sym
      transformer ||= opts.fetch(sym, :default)
      transformer = klass.get_subclass_instance(transformer) if transformer.is_a?(Symbol)
      transformer
    end
  end

  class Input
    attr_reader :form
    attr_reader :type
    attr_reader :opts
    def initialize(form, type, opts={})
      @form = form
      @type = type
      @opts = opts
    end
    def obj
      form.obj
    end
    def format
      form.formatter.format(self)
    end
    def serialize
      form.serializer.serialize(format)
    end
  end

  class Tag
    attr_reader :form
    attr_reader :type
    attr_reader :attr
    attr_reader :children

    def initialize(form, type, attr={}, &block)
      @form = form
      @type = type
      @attr = attr
      @children = []
    end

    def <<(child)
      children << child
    end

    def serialize
      form.serializer.serialize(self)
    end
  end

  module SubclassMap
    def self.extended(klass)
      klass.const_set(:MAP, {})
    end

    def get_subclass_instance(type)
      subclass = self::MAP[type] || self::MAP[:default]
      raise Error, "invalid #{name.to_s.downcase}: #{type} (valid #{name.to_s.downcase}s: #{klass::MAP.keys.join(', ')})" unless subclass 
      subclass.new
    end

    def inherited(subclass)
      self::MAP[subclass.name.split('::').last.downcase.to_sym] = subclass
      super
    end
  end

  class Formatter
    extend SubclassMap
  end

  class Formatter::Default < Formatter
    def format(input)
      form = input.form
      attr = input.opts.dup
      tag = case t = input.type
      when :textarea, :fieldset, :div
        if val = attr.delete(:value)
          tg = Tag.new(form, t, attr)
          tg << val
          tg
        else
          tg = Tag.new(form, t, input.opts)
        end
      else
        Tag.new(form, :input, attr.merge!(:type=>t))
      end

      if l = attr.delete(:label)
        label = Tag.new(form, :label)
        label << "#{l}: "
        label << tag
        tag = label
      end

      tag
    end
  end

  class Serializer
    extend SubclassMap
  end

  class Serializer::Default < Serializer
    SELF_CLOSING = [:img, :input]
    def serialize(tag)
      if tag.is_a?(String)
        h tag
      elsif SELF_CLOSING.include?(tag.type)
        "<#{tag.type}#{attr_html(tag)}/>"
      else
        "#{serialize_open(tag)}#{children_html(tag)}#{serialize_close(tag)}"
      end
    end

    def serialize_open(tag)
      "<#{tag.type}#{attr_html(tag)}>"
    end

    def serialize_close(tag)
      "</#{tag.type}>"
    end

    private

    # Borrowed from Rack::Utils
    ESCAPE_HTML = {
      "&" => "&amp;",
      "<" => "&lt;",
      ">" => "&gt;",
      "'" => "&#39;",
      '"' => "&quot;",
    }
    ESCAPE_HTML_PATTERN = Regexp.union(ESCAPE_HTML.keys)
    # Escape ampersands, brackets and quotes to their HTML/XML entities.
    def h(string)
      string.to_s.gsub(ESCAPE_HTML_PATTERN){|c| ESCAPE_HTML[c] }
    end

    def attr_html(tag)
      " #{tag.attr.sort_by{|k,v| k.to_s}.map{|k, v| "#{k}=\"#{h v}\""}.join(' ')}" unless tag.attr.empty?
    end

    def children_html(tag)
      tag.children.map{|x| serialize(x)}.join
    end
  end
end
