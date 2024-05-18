module SwombatTools
  module Team
    extend ActiveSupport::Concern

    included do
      def test_swombat?
        true
      end
    end

  end
end

puts "Loaded Team Concern"
