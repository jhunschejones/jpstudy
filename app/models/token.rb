class Token
  class << self
    def generate(cost: BCrypt::Engine.cost, expires_at: Time.now.utc + 24.hours)
      Secrets::Token.new(SecureRandom.base58(24), expires_at: expires_at, cost: cost)
    end
  end

  attr_reader :expires_at

  def initialize(token, expires_at: nil, cost: BCrypt::Engine.cost)
    @token = token
    @expires_at = expires_at
    @cost = cost
  end

  def valid_for?(value)
    (@expires_at.nil? || @expires_at.utc > Time.now.utc) && BCrypt::Password.new(value) == @token
  end

  def to_s
    @token.to_s
  end

  def digest
    BCrypt::Password.create(@token.to_s, cost: @cost)
  end
end
