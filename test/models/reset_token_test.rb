require "test_helper"

class ResetTokenTest < ActiveSupport::TestCase
  describe ".is_valid?" do
    setup do
      @test_token = Token.generate
      @test_user = users(:carl)
      @test_user.update!(
        reset_digest: @test_token.digest,
        reset_sent_at: Time.now.utc
      )
    end

    it "returns false when the user record doesn't indicate that a reset token was generated" do
      @test_user.update!(
        reset_digest: nil,
        reset_sent_at: nil
      )
      refute ResetToken.is_valid?(user: @test_user, token: @test_token)
    end

    it "returns false when the user reset token has expired" do
      travel 5.hours do
        refute ResetToken.is_valid?(user: @test_user, token: @test_token)
      end
    end

    it "returns false when the digest doesn't match the user reset digest" do
      another_token = Token.generate
      refute ResetToken.is_valid?(user: @test_user, token: another_token)
    end

    it "returns true when not expired and the digest matches the user reset digest" do
      assert ResetToken.is_valid?(user: @test_user, token: @test_token)
    end
  end
end
