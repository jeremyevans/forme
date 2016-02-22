require 'i18n'
require 'sequel/plugins/forme'

module Sequel # :nodoc:
  module Plugins # :nodoc:
    # This Sequel plugin extends Forme usage with Sequel to support I18n
    module FormeI18n
      module SequelFormI18n
        # Checks if there's a translation for the
        # 'models.<table_name>.<association>' key and merge it to the options
        # with the :legend key
        #
        # Calls the original Sequel::Plugins::Forme::SequelForm method
        def subform(association, opts={}, &block)
          i18n_key = "models.#{obj.class.table_name}.#{association}"

          if opts[:legend].nil? && I18n.exists?(i18n_key)
            opts[:legend] = I18n.t(i18n_key)
          end

          super
        end
      end

      def self.apply(model)
        model.plugin(:forme)
      end

      module InstanceMethods

        # Includes the SequelFormI18n methods on the original returned class
        def forme_form_class(base)
          klass = super
          klass.send(:include, SequelFormI18n)
          klass
        end

        # Checks if there's a translation for the 'models.<table_name>.<field>'
        # key and merge it to the options with the :label key
        #
        # Calls the original Sequel::Plugins::Forme method
        def forme_input(form, field, opts)
          i18n_key = "models.#{self.class.table_name}.#{field}"

          if opts[:label].nil? && I18n.exists?(i18n_key)
            opts[:label] = I18n.t(i18n_key)
          end

          super
        end
      end
    end
  end
end
