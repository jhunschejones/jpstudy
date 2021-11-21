class TokenSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.is_a?(Token)
  end

  def serialize(token)
    super("value" => token.to_s, "expires_at" => token.expires_at)
  end

  def deserialize(hash)
    Token.new(hash["value"], expires_at: hash["expires_at"])
  end
end
