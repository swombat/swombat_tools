module SwombatTools
  module Team
    extend ActiveSupport::Concern

    included do
      puts "Team Concern included"
    end

    def test_swombat?
      true
    end
  end
end

puts "Loaded Team Concern"
