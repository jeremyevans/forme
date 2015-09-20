module Forme
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
      time.is_a?(Time) ? (time.strftime('%Y-%m-%dT%H:%M:%S') + sprintf(".%06d", time.usec)) : (time.strftime('%Y-%m-%dT%H:%M:%S.') + time.strftime('%N')[0...6])
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
        if tag.type.to_s == 'input' && %w'date datetime datetime-local'.include?((tag.attr[:type] || tag.attr['type']).to_s)
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
