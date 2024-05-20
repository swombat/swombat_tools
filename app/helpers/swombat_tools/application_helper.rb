module SwombatTools
  module ApplicationHelper

    def access_token_mask(token)
      token[0..3] + "****" + token[-4..-1]
    end

  end
end
