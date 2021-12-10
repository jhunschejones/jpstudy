class ResetToken < Token
  class << self
    def is_valid?(user:, token:)
      return false unless user.reset_sent_at && user.reset_digest
      new(
        token.to_s,
        expires_at: user.reset_sent_at.utc + 4.hours
      ).valid_for?(user.reset_digest)
    end
  end
end
