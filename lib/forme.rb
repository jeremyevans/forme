require 'date'
require 'bigdecimal'

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
  TRANSFORMER_TYPES = [:formatter, :serializer, :wrapper, :error_handler, :helper, :labeler, :inputs_wrapper]

  # Transformer symbols shared by wrapper and inputs_wrapper
  SHARED_WRAPPERS = [:tr, :table, :ol, :fieldset_ol]

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

  # Create a RawString using the given string, which will disable automatic
  # escaping for that string.
  def self.raw(s)
    RawString.new(s)
  end

  # If there is a related transformer, call it with the given +args+ and +block+.
  # Otherwise, attempt to return the initial input without modifying it.
  def self.transform(type, trans_name, default_opts, *args, &block)
    if trans = transformer(type, trans_name, default_opts)
      trans.call(*args, &block)
    else
      case type
      when :inputs_wrapper
        yield
      when :labeler, :error_handler, :wrapper, :helper
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
  def self.transformer(type, trans, default_opts)
    case trans
    when Symbol
      TRANSFORMERS[type][trans] || raise(Error, "invalid #{type}: #{trans.inspect} (valid #{type}s: #{TRANSFORMERS[type].keys.map(&:inspect).join(', ')})")
    when Hash
      if trans.has_key?(type)
        if v = trans[type]
          transformer(type, v, default_opts)
        end
      else
        transformer(type, nil, default_opts)
      end
    when nil
      transformer(type, default_opts[type], nil) if default_opts
    else
      if trans.respond_to?(:call)
        trans
      else
        raise Error, "#{type} #{trans.inspect} must respond to #call"
      end
    end
  end
end

%w'form input tag raw version'.each{|f| require File.expand_path("../forme/#{f}", __FILE__)}
%w'error_handler formatter helper inputs_wrapper labeler serializer wrapper'.each{|f| require File.expand_path("../forme/transformers/#{f}", __FILE__)}
