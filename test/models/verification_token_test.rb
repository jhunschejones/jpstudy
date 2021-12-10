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

    it "returns false when the user record doesn't indicate that a verification token was generated" do
      @test_user.update!(
        verification_digest: nil,
        verification_sent_at: nil
      )
      refute VerificationToken.is_valid?(user: @test_user, token: @test_token)
    end

    it "returns false when the user verification token has expired" do
      travel 5.hours do
        refute VerificationToken.is_valid?(user: @test_user, token: @test_token)
      end
    end

    it "returns false when the digest doesn't match the user verification digest" do
      another_token = Token.generate
      refute VerificationToken.is_valid?(user: @test_user, token: another_token)
    end

    it "returns true when not expired and the digest matches the user verification digest" do
      assert VerificationToken.is_valid?(user: @test_user, token: @test_token)
    end
  end
end
