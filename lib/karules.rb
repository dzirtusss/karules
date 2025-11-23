# frozen_string_literal: true

require_relative "karules/dsl"
require_relative "karules/version"

# Base class for Karabiner configuration
# Users should subclass this and override the config method
class KaRules
  include KaRulesDSL

  def config
    # Override this method in your configuration file
    # See examples/config.rb for a complete example
  end
end
