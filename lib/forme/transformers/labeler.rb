module Forme
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
      unless id = input.opts[:id]
        if key = input.opts[:key]
          namespaces = input.form_opts[:namespace]
          id = "#{namespaces.join('_')}#{'_' unless namespaces.empty?}#{key}"
          if key_id = input.opts[:key_id]
            id << "_#{key_id.to_s}"
          end
        end
      end

      label_attr = input.opts[:label_attr]
      label_attr = label_attr ? label_attr.dup : {}
      label_attr[:for] ||= input.opts.fetch(:label_for, id)
      lpos = input.opts[:label_position] || ([:radio, :checkbox].include?(input.type) ? :after : :before)

      Forme.attr_classes(label_attr, "label-#{lpos}")
      label = input.tag(:label, label_attr, [input.opts[:label]])

      t = if lpos == :before
        [label, tag]
      else
        [tag, label]
      end

      t
    end
  end

  # Labeler that creates BS3 label tags referencing the the given tag's id 
  # using a +for+ attribute. Requires that all tags with labels have +id+ fields.
  #
  # Registered as :bs3.
  class Labeler::Bootstrap3
    Forme.register_transformer(:labeler, :bs3, new)

    # Return an array with a label tag as the first entry and +tag+ as
    # a second entry.  If the +input+ has a :label_for option, use that,
    # otherwise use the input's :id option.  If neither the :id or
    # :label_for option is used, the label created will not be
    # associated with an input.
    def call(tag, input)
      unless id = input.opts[:id]
        if key = input.opts[:key]
          namespaces = input.form_opts[:namespace]
          id = "#{namespaces.join('_')}#{'_' unless namespaces.empty?}#{key}"
          if key_id = input.opts[:key_id]
            id << "_#{key_id.to_s}"
          end
        end
      end

      label_attr = input.opts[:label_attr]
      label_attr = label_attr ? label_attr.dup : {}
      
      label_attr[:for] = label_attr[:for] === false ? nil : input.opts.fetch(:label_for, id)
      label = input.opts[:label]
      lpos = input.opts[:label_position] || ([:radio, :checkbox].include?(input.type) ? :after : :before)
      
      case input.type
      when :checkbox, :radio
        label = if lpos == :before
          [label, ' ', tag]
        else
          [tag, ' ', label]
        end
        input.tag(:label, label_attr, label)
      when :submit
        [tag]
      else
        label = input.tag(:label, label_attr, [input.opts[:label]])
        if lpos == :after
          [tag, ' ', label]
        else
          [label, ' ', tag]
        end
      end
    end
  end
end
