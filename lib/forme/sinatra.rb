# frozen-string-literal: true

if RUBY_VERSION >= '2'
  warn('forme/sinatra and Forme::Sinatra::ERB are deprecated and will be removed in a future version, switch to forme/erb and Forme::ERB::Helper', :uplevel=>1)
end

require_relative 'erb'

module Forme
  # For backwards compatibility only.  New code should
  # require 'forme/erb' and include the Forme::ERB::Helper
  # class:
  #
  #   helpers Forme::ERB::Helper
  module Sinatra
    ERB = Forme::ERB::Helper
    Erubis = ERB
    Form = Forme::Template::Form
    HIDDEN_TAGS = Forme::ERB::HIDDEN_TAGS
  end
end
