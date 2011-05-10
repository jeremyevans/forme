module Forme
  module Sinatra
    module ERB
      def form(obj, attr={}, opts={}, &block)
        f = ::Forme::Form.new(obj, opts)
        output = eval('@_out_buf', block.binding)
        output << f.open(attr)
        yield f
        output << f.close
      end
    end 
    Erubis = ERB
  end
end
