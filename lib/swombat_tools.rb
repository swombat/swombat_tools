require "swombat_tools/version"
require "swombat_tools/engine"
require "swombat_tools/array_patch"

module SwombatTools
  class Engine < ::Rails::Engine
    isolate_namespace SwombatTools

    config.to_prepare do
      ::Team.include(SwombatTools::Team)
      ::ApplicationHelper.include(SwombatTools::ApplicationHelper)
      ::Array.include(SwombatTools::ArrayPatch)
      if (File.read("Gemfile").include?("anthropic"))
        API_CLASSES = [::ClaudeApi, ::OpenAiApi]
      end
    end

  end
end
