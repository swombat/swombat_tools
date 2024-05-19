require "swombat_tools/version"
require "swombat_tools/engine"

module SwombatTools
  class Engine < ::Rails::Engine
    isolate_namespace SwombatTools

    config.to_prepare do
      ::Team.include(SwombatTools::Team)
    end
  end
end
