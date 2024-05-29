module SwombatTools
  module Team
    extend ActiveSupport::Concern

    included do
      def site_admin?
        team.id == ENV.fetch("SITE_ADMIN_TEAM_ID", 1).to_i
      end
    end

  end
end
