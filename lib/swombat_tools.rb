require "swombat_tools/version"
require "swombat_tools/engine"

module SwombatTools
  class Engine < ::Rails::Engine
    isolate_namespace SwombatTools

    config.to_prepare do
      ::Team.include(SwombatTools::Team)

      # ::Team.class_eval do
      #   def is_?
      #     true
      #   end
      # end
    end
  end
end

puts "Engine loaded"
