require "swombat_tools/version"
require "swombat_tools/engine"

module SwombatTools
  class Engine < ::Rails::Engine
    isolate_namespace SwombatTools

    config.to_prepare do
      ::Team.include(SwombatTools::Team)
      ::ApplicationHelper.include(SwombatTools::ApplicationHelper)
      if (File.read("Gemfile").include?("anthropic"))
        API_CLASSES = [::ClaudeApi, ::OpenAiApi]
      end
    end

  end
end
