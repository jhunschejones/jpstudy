class Token
  class << self
    def generate(cost: BCrypt::Engine.cost, expires_at: Time.now.utc + 4.hours)
      new(SecureRandom.base58(24), expires_at: expires_at, cost: cost)
    end
  end

  attr_reader :expires_at

  def initialize(token, expires_at: nil, cost: BCrypt::Engine.cost)
    @token = token
    @expires_at = expires_at
    @cost = cost
  end

  def valid_for?(compare_to_digest)
    # BCrypt overrides the definition of `==` here, this is not a direct string comparison
    not_expired? && BCrypt::Password.new(compare_to_digest) == @token
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def to_s
    @token.to_s
  end

  def digest
    BCrypt::Password.create(@token, cost: @cost)
  end

  private

  def not_expired?
    @expires_at.nil? || (@expires_at.utc > Time.now.utc)
  end
end
