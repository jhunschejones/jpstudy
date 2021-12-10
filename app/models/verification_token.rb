class VerificationToken < Token
  class << self
    def is_valid?(user:, token:)
      return false unless user.verification_sent_at && user.verification_digest
      new(
        token.to_s,
        expires_at: user.verification_sent_at.utc + 4.hours
      ).valid_for?(user.verification_digest)
    end
  end
end
