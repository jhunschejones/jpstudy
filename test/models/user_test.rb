require "test_helper"

class UserTest < ActiveSupport::TestCase
  describe "#verify_email" do
    setup do
      verification_token = VerificationToken.generate
      users(:carl).update!(verification_digest: verification_token.digest)
    end

    it "updates expected user attributes" do
      freeze_time do
        users(:carl).verify_email
        assert users(:carl).verified?
        assert_equal Time.now.utc, users(:carl).verified_at
      end
    end
  end

  describe "#trial_active?" do
    it "returns false when a user does not have a trial" do
      users(:carl).update!(trial_ends_at: nil)
      refute users(:carl).trial_active?
    end

    it "returns false when a user has an expired trial" do
      users(:carl).update!(trial_ends_at: Time.now - 1.day)
      refute users(:carl).trial_active?
    end

    it "returns true when a user has a trial that is active" do
      assert users(:carl).trial_active?
    end
  end

  describe "#has_reached_word_limit?" do
    setup do
      User.reset_counters(users(:carl).id, :words)
      users(:carl).reload
    end

    it "returns false when no word limit is set" do
      users(:carl).update!(word_limit: nil)
      refute users(:carl).has_reached_word_limit?
    end

    it "returns false when the user has not reached their word limit" do
      refute users(:carl).has_reached_word_limit?
    end

    it "returns true when the user has reached their word limit" do
      users(:carl).update!(word_limit: 20)
      assert users(:carl).has_reached_word_limit?
    end
  end

  describe "#has_reached_kanji_limit?" do
    setup do
      User.reset_counters(users(:carl).id, :kanji)
      users(:carl).reload
    end

    it "returns false when no kanji limit is set" do
      users(:carl).update!(kanji_limit: nil)
      refute users(:carl).has_reached_kanji_limit?
    end

    it "returns false when the user has not reached their kanji limit" do
      refute users(:carl).has_reached_kanji_limit?
    end

    it "returns true when the user has reached their kanji limit" do
      users(:carl).update!(kanji_limit: 3)
      assert users(:carl).has_reached_kanji_limit?
    end
  end

  describe "#reset_password" do
    it "sets new password" do
      assert users(:carl).reset_password("a_new_password")
      assert_nil users(:carl).reset_digest
      assert users(:carl).try(:authenticate, "a_new_password")
    end

    # In order to get a reset token, the user would have had to access their email,
    # thus, we can verify their email now as well if it wasn't already verified.
    it "verifies the user" do
      freeze_time do
        assert users(:carl).reset_password("a_new_password")
        assert users(:carl).verified?
        assert_equal Time.now.utc, users(:carl).verified_at
      end
    end

    it "returns false on failure" do
      refute users(:carl).reset_password("bad")
    end
  end

  describe "#active_subscription" do
    describe "when there is no active subscription" do
      setup do
        users(:carl).update!(square_customer_id: 1234)
        subscription = {
          id: "1234",
          start_date: Time.now.to_s,
          charged_through_date: (Time.now + 30.days).to_s,
          status: "INACTIVE",
          buyer_self_management_token: "test-token"
        }
        search_subscriptions_result_data = mock()
        search_subscriptions_result = mock()
        subscriptions = mock()
        search_subscriptions_result_data.stubs(:subscriptions).returns([subscription])
        search_subscriptions_result.stubs(:error?).returns(false)
        search_subscriptions_result.stubs(:data).returns(search_subscriptions_result_data)
        subscriptions.stubs(:search_subscriptions).returns(search_subscriptions_result)
        SQUARE_CLIENT.stubs(:subscriptions).returns(subscriptions)
      end

      it "returns nil" do
        assert_nil users(:carl).active_subscription
      end
    end

    describe "when the user has an active subscription" do
      setup do
        users(:carl).update!(square_customer_id: 1234)
        subscription = {
          id: "1234",
          start_date: Time.now.to_s,
          charged_through_date: (Time.now + 30.days).to_s,
          status: "ACTIVE",
          buyer_self_management_token: "test-token"
        }
        search_subscriptions_result_data = mock()
        search_subscriptions_result = mock()
        subscriptions = mock()
        search_subscriptions_result_data.stubs(:subscriptions).returns([subscription])
        search_subscriptions_result.stubs(:error?).returns(false)
        search_subscriptions_result.stubs(:data).returns(search_subscriptions_result_data)
        subscriptions.stubs(:search_subscriptions).returns(search_subscriptions_result)
        SQUARE_CLIENT.stubs(:subscriptions).returns(subscriptions)
      end

      it "returns the first active subscription" do
        assert users(:carl).active_subscription.is_a?(Subscription)
        assert users(:carl).active_subscription.active?
        assert_equal "1234", users(:carl).active_subscription.id
      end
    end
  end
end
