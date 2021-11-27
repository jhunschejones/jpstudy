require "test_helper"

class TokenTest < ActiveSupport::TestCase
  describe ".generate" do
    it "returns a token" do
      assert Token.generate.is_a?(Token)
    end

    it "sets a default expiration of 4 hours" do
      freeze_time do
        assert_equal Time.now.utc + 4.hours, Token.generate.expires_at
      end
    end
  end

  describe "#valid_for?" do
    setup do
      @test_token = Token.generate
    end

    it "returns false when the token has expired" do
      travel 5.hours do
        refute @test_token.valid_for?(@test_token.digest)
      end
    end

    it "returns false if the digests don't match" do
      different_token = Token.generate
      refute @test_token.valid_for?(different_token.digest)
    end

    it "returns false if the comparison digest doesnt hash" do
      refute @test_token.valid_for?(SecureRandom.base58(24))
    end

    it "returns true when not expired and the digests match" do
      assert @test_token.valid_for?(@test_token.digest)
    end
  end
end
