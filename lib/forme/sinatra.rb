require 'forme/erb'

module Forme
  # For backwards compatibility only.  New code should
  # require 'forme/erb' and include the Forme::ERB::Helper
  # class:
  #
  #   helpers Forme::ERB::Helper
  module Sinatra
    ERB = Forme::ERB::Helper
    Erubis = ERB
    Form = Forme::ERB::Form
    HIDDEN_TAGS = Forme::ERB::HIDDEN_TAGS
  end
end
