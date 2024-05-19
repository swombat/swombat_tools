# Override to use keys instead of ENV
def invitation_only?
  InvitationKey.all.any?
end

def invitation_keys
  InvitationKey.all.collect(&:key)
end
