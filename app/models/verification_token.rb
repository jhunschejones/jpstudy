class VerificationToken < Token
  class << self
    def is_valid?(user:, token:)
      new(
        token.to_s,
        expires_at: user.verification_sent_at + 4.hours
      ).valid_for?(user.verification_digest)
    end
  end
end
