require 'forme/version'

module Forme
  class Error < StandardError
  end

  class Form
    attr_reader :obj
    attr_reader :opts
    attr_reader :formatter
    attr_reader :labeler
    attr_reader :serializer
    def initialize(obj=nil, opts={})
      @obj = obj
      @opts = opts
      @formatter = find_transformer(Formatter, :formatter)
      @labeler = find_transformer(Labeler, :labeler)
      @serializer = find_transformer(Serializer, :serializer)
    end

    def input(field, opts={})
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

    def open(attr)
      serializer.serialize_open(Tag.new(:form, attr))
    end

    def close
      serializer.serialize_close(Tag.new(:form))
    end

    def tag(type, attr={})
      serialize(Tag.new(type, attr))
    end

    private

    def find_transformer(klass, sym)
      transformer ||= opts.fetch(sym, :default)
      transformer = klass.get_subclass_instance(transformer) if transformer.is_a?(Symbol)
      transformer
    end

    def format(input)
      formatter.call(self, input)
    end

    def serialize(tag)
      serializer.call(tag)
    end
  end

  class Input
    attr_reader :type
    attr_reader :opts
    def initialize(type, opts={})
      @type = type
      @opts = opts
    end
  end

  class Tag
    attr_reader :type
    attr_reader :attr
    attr_reader :children

    def initialize(type, attr={}, children=[])
      @type = type
      @attr = attr
      @children = children
    end

    def <<(child)
      children << child
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

      tag
    end

    private

    def format_input(form, type, opts)
      Tag.new(:input, opts.merge!(:type=>type))
    end

    def format_select(form, type, opts)
      if os = opts.delete(:options)
        vm = opts.delete(:value_method)
        tm = opts.delete(:text_method)
        sel = opts.delete(:selected)
        os = os.map do |x|
          attr = {}
          if tm
            text = x.send(tm)
            if vm
              val = x.send(vm)
              attr[:value] = val
              attr[:selected] = :selected if val == sel
            else
              attr[:selected] = :selected if text == sel
            end
            Tag.new(:option, attr, [text])
          elsif x.is_a?(Array)
            val = x.last
            attr[:value] = val
            attr[:selected] = :selected if val == sel
            Tag.new(:option, attr, [x.first])
          else
            attr[:selected] = :selected if x == sel
            Tag.new(:option, attr, [x])
          end
        end
      end
      Tag.new(type, opts, os)
    end

    def format_textarea(form, type, opts)
      if val = opts.delete(:value)
        Tag.new(type, opts, [val])
      else
        Tag.new(type, opts)
      end
    end
  end

  class Labeler
    extend SubclassMap
  end

  class Labeler::Default < Labeler
    def call(label, tag)
      Tag.new(:label, {}, ["#{label}: ", tag])
    end
  end

  class Labeler::Explicit < Labeler
    def call(label, tag)
      raise Error, "Explicit labels require an id field" unless id = tag.attr[:id]
      [Tag.new(:label, {:for=>id}, label), tag]
    end
  end

  class Serializer
    extend SubclassMap
  end

  class Serializer::Default < Serializer
    SELF_CLOSING = [:img, :input]
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
  end
end
