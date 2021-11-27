require "test_helper"

class VerificationTokenTest < ActiveSupport::TestCase
  describe ".is_valid?" do
    setup do
      @test_token = Token.generate
      @test_user = users(:carl)
      @test_user.update!(
        verification_digest: @test_token.digest,
        verification_sent_at: Time.now.utc
      )
    end

    it "returns false when user verification has expired" do
      travel 5.hours do
        refute VerificationToken.is_valid?(user: @test_user, token: @test_token)
      end
    end

    it "returns false when digest doesn't match user verification digest" do
      another_token = Token.generate
      refute VerificationToken.is_valid?(user: @test_user, token: another_token)
    end

    it "returns true when not expired and digest matches user verification digest" do
      assert VerificationToken.is_valid?(user: @test_user, token: @test_token)
    end
  end
end
