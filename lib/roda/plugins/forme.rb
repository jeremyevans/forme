require 'forme/erb'

class Roda
  module RodaPlugins
    module Forme
      # Require the render plugin, since forme template integration
      # only makes sense with it.
      def self.load_dependencies(app)
        app.plugin :render
      end

      InstanceMethods = ::Forme::ERB::Helper
    end

    register_plugin(:forme, Forme)
  end
end
