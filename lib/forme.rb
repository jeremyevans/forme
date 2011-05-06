module Forme
  class Error < StandardError
  end

  module Base
    WIDGETS = [:text, :password, :hidden, :checkbox, :radio, :submit, :textarea, :fieldset, :legend, :p, :div, :ol, :ul, :label, :select, :optgroup, :legend, :p, :li, :label, :option]

    [:text, :password, :hidden, :checkbox, :radio, :submit].each do |x|
      class_eval("def #{x}(attr={}, opts={}) Tag.new(:input, attr.merge(:type=>:#{x}), opts.merge(:self_close=>true)) end", __FILE__, __LINE__)
    end
    [:textarea, :fieldset, :legend, :p, :div, :ol, :ul, :label, :select, :optgroup].each do |x|
      class_eval("def #{x}(attr={}, opts={}, &block) Tag.new(:#{x}, attr, opts, &block) end", __FILE__, __LINE__)
    end
    [:legend, :p, :li, :label].each do |x|
      class_eval("def #{x}(text=nil, attr={}, opts={}) Tag.new(:#{x}, attr, opts.merge(:text=>text)) end", __FILE__, __LINE__)
    end

    def option(text, value=nil, attr={}, opts={})
      attr = attr.merge(:value=>value) if value
      Tag.new(:option, attr, opts.merge(:text=>text))
    end
  end
  include Base

  class Tag
    attr_reader :type
    attr_reader :opts
    attr_reader :attr
    attr_reader :children

    include Base

    def initialize(type, attr={}, opts={})
      @type = type
      @attr = attr
      @opts = opts
      @children = []
      self << opts[:text] if opts[:text]
      yield self if block_given?
    end

    def html(formatter=nil)
      formatter ||= opts.fetch(:formatter, :html)
      raise Error, "self closing tags can't have children" if sc = opts[:self_close] and !children.empty?
      if formatter.is_a?(Symbol)
        klass = Formatter::MAP[formatter]
        raise Error, "invalid formatter: #{formatter} (valid formatters: #{Formatter::MAP.keys.join(', ')})" unless klass
        formatter = klass.new
      end
      formatter.format(self)
    end

    WIDGETS.each do |x|
      class_eval("def #{x}(*) add_tag(super) end", __FILE__, __LINE__)
    end

    def <<(s)
      children << s
    end

    private

    def add_tag(tag)
      children << tag
      tag
    end
  end

  class Tag::Formatter
    MAP = {}
    def self.inherited(subclass)
      MAP[subclass.name.split('::').last.downcase.to_sym] = subclass
      super
    end
  end

  class Tag::Formatter::HTML < Tag::Formatter
    def format(tag)
      sc = tag.opts[:self_close]
      "<#{tag.type}#{attr_html(tag)}#{sc ? '/>' : ">"}#{children_html(tag)}#{"</#{tag.type}>" unless sc}"
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
      tag.children.map{|x| x.respond_to?(:html) ? x.html(self) : x.to_s}.join
    end
  end

  def form(action=nil, attr={}, opts={}, &block)
    if action
      attr = attr.merge(:action=>action)
      attr[:method] ||= :post
    end
    Tag.new(:form, attr, opts, &block).html
  end

  WIDGETS.each do |x|
    class_eval("def #{x}(*) super.html end", __FILE__, __LINE__)
  end
end
