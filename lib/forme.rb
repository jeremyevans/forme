module Forme
  class Error < StandardError
  end

  module Base
    WIDGETS = [:text, :password, :hidden, :checkbox, :radio, :submit, :textarea, :fieldset, :legend, :p, :div, :ol, :ul, :label, :select, :optgroup, :legend, :li, :label, :option]

    [:text, :password, :hidden, :checkbox, :radio, :submit].each do |x|
      class_eval("def #{x}(opts={}) Tag.new(:input, {:type=>:#{x}}.merge!(opts)) end", __FILE__, __LINE__)
    end
    [:textarea, :fieldset, :legend, :div, :ol, :ul, :label, :select, :optgroup].each do |x|
      class_eval("def #{x}(opts={}, &block) Tag.new(:#{x}, opts, &block) end", __FILE__, __LINE__)
    end
    [:legend, :p, :li, :label].each do |x|
      class_eval("def #{x}(text=nil, opts={}, &block) Tag.new(:#{x}, opts.merge(:text=>text), &block) end", __FILE__, __LINE__)
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

    def initialize(type, opts={}, &block)
      @type = type
      @attr = opts[:attr] || {}
      @opts = opts
      [:type, :method, :class, :id, :cols, :rows, :action, :name, :value].each do |x|
        @attr[x] = opts[x] if opts[x]
      end
      @children = []
      self << opts[:text] if opts[:text]
      (block.arity == 1 ? yield(self) : instance_eval(&block)) if block
    end

    def html(formatter=nil)
      formatter ||= opts.fetch(:formatter, :default)
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
      raise Error, "self closing tags can't have children" if self_close?
      children << s
    end

    def clone(opts={})
      t = super()
      t.instance_variable_set(:@opts,  self.opts.merge(opts))
      t
    end

    def input(fields, opts={})
      raise Error, "can only use #input if an :obj has been set" unless obj = self.opts[:obj]
      Array(fields).each{|f| add_tag(obj.send(:forme_tag, f, opts))}
    end

    def self_close?
      [:input, :img].include?(type)
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

  class Tag::Formatter::Default < Tag::Formatter
    def format(tag)
      sc = tag.self_close?
      if label = tag.opts[:label]
        format(Tag.new(:label, :text=>"#{label}: "){self << tag.clone(:label=>false)})
      else
        "<#{tag.type}#{attr_html(tag)}#{sc ? '/>' : ">"}#{children_html(tag)}#{"</#{tag.type}>" unless sc}"
      end
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
      tag.children.map{|x| x.respond_to?(:html) ? x.html(self) : (h x.to_s)}.join
    end
  end

  class Tag::Formatter::Labels < Tag::Formatter
  end

  def form(action_or_obj=nil, opts={}, &block)
    case action_or_obj
    when nil
      # nothing
    when String
      opts = {:action=>action_or_obj, :method=>:post}.merge!(opts)
    else
      opts = {:obj => action_or_obj}.merge!(opts)
    end
    Tag.new(:form, opts, &block).html
  end

  WIDGETS.each do |x|
    class_eval("def #{x}(*) super.html end", __FILE__, __LINE__)
  end
end
