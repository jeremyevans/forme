require 'forme'

module Sequel
  module Plugins
    # This Sequel plugin allows easy use of Forme with Sequel.
    module Forme
      class SequelInput
        include ::Forme

        attr_reader :obj
        attr_reader :field
        attr_reader :opts
        attr_reader :namespace

        def initialize(obj, field, opts)
          @obj, @field, @opts = obj, field, opts
          @namespace ||= obj.model.name.downcase
          opts[:label] ||= humanize(field)
        end

        def input
          if sch = obj.model.db_schema[field] 
            meth = :"input_#{sch[:type]}"
            opts[:id] ||= "#{namespace}_#{field}"
            opts[:name] ||= "#{namespace}[#{field}]"
            if respond_to?(meth, true)
              send(meth, sch)
            else
              input_other(sch)
            end
          elsif ref = obj.model.association_reflection(field)
            case ref[:type]
            when :many_to_one
              association_many_to_one(ref)
            else
              raise Error, "Only many_to_one associations currently handled"
            end
          end
        end

        private

        def association_many_to_one(ref)
          key = ref[:key]
          opts[:id] ||= "#{namespace}_#{key}"
          opts[:name] ||= "#{namespace}[#{key}]"
          opts[:value] ||= obj.send(key)
          os = obj.send(:_apply_association_options, ref, ref.associated_class.dataset).unlimited.all.map{|a| [a.name, a.id]}
          os.unshift '' if (sch = obj.model.db_schema[key])  && sch[:allow_null]
          opts[:options] = os
          Input.new(:select, opts)
        end

        def humanize(s)
          s = s.to_s
          s.respond_to?(:humanize) ? s.humanize : s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
        end

        def input_boolean(sch)
          if sch[:allow_null]
            v = opts[:value] || obj.send(field)
            opts[:value] = (v ? 't' : 'f') unless v.nil?
            opts[:options] = ['', ['True', 't'], ['False', 'f']]
            Input.new(:select, opts)
          else
            opts[:checked] = obj.send(field)
            opts[:value] = 't'
            Input.new(:checkbox, opts)
          end
        end

        def input_other(sch)
          opts[:value] ||= obj.send(field)
          Input.new(:text, opts)
        end
      end

      module InstanceMethods
        # Return Forme::Input instance for field and opts
        def forme_input(field, opts)
          SequelInput.new(self, field, opts).input
        end
      end
    end
  end
end
