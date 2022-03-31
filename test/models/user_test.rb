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
      users(:carl).update!(word_limit: 25)
      assert_equal 21, users(:carl).words.count
      refute users(:carl).has_reached_word_limit?
    end

    it "returns true when the user has reached their word limit" do
      users(:carl).update!(word_limit: 21)
      assert_equal 21, users(:carl).words.count
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
      users(:carl).update!(kanji_limit: 5)
      assert_equal 3, users(:carl).kanji.count
      refute users(:carl).has_reached_kanji_limit?
    end

    it "returns true when the user has reached their kanji limit" do
      users(:carl).update!(kanji_limit: 3)
      assert_equal 3, users(:carl).kanji.count
      assert users(:carl).has_reached_kanji_limit?
    end
  end

  describe "#has_reached_daily_word_target?" do
    it "returns false when no daily word target is set" do
      refute users(:carl).has_reached_daily_word_target?
    end

    describe "when daily word target is set" do
      setup do
        users(:carl).update!(daily_word_target: 1)
      end

      it "returns false when daily word target has not been met yet" do
        refute users(:carl).has_reached_daily_word_target?
      end

      it "returns true when user has reached daily word target" do
        Word.create!(japanese: "自己紹介", english: "self introduction", user: users(:carl), cards_created_at: Time.now.utc)
        assert users(:carl).has_reached_daily_word_target?
      end

      # To keep the flash message from continuing to show up if more words are added past the users target
      it "returns false when user has passed daily word target" do
        Word.create!(japanese: "自己紹介", english: "self introduction", user: users(:carl), cards_created_at: Time.now.utc)
        Word.create!(japanese: "お先に失礼します", english: "pardon me for leaving first", user: users(:carl), cards_created_at: Time.now.utc)
        refute users(:carl).has_reached_daily_word_target?
      end
    end
  end

  describe "#has_reached_or_exceeded_daily_word_target?" do
    it "returns false when no daily word target is set" do
      refute users(:carl).has_reached_or_exceeded_daily_word_target?
    end

    describe "when daily word target is set" do
      setup do
        users(:carl).update!(daily_word_target: 1)
      end

      it "returns false when daily word target has not been met yet" do
        refute users(:carl).has_reached_or_exceeded_daily_word_target?
      end

      it "returns true when user has reached daily word target" do
        Word.create!(japanese: "自己紹介", english: "self introduction", user: users(:carl), cards_created_at: Time.now.utc)
        assert users(:carl).has_reached_or_exceeded_daily_word_target?
      end

      it "returns true when user has passed daily word target" do
        Word.create!(japanese: "自己紹介", english: "self introduction", user: users(:carl), cards_created_at: Time.now.utc)
        Word.create!(japanese: "お先に失礼します", english: "pardon me for leaving first", user: users(:carl), cards_created_at: Time.now.utc)
        assert users(:carl).has_reached_or_exceeded_daily_word_target?
      end
    end
  end

  describe "#has_reached_daily_kanji_target?" do
    it "returns false when no daily kanji target is set" do
      refute users(:carl).has_reached_daily_kanji_target?
    end

    describe "when daily kanji target is set" do
      setup do
        users(:carl).update!(daily_kanji_target: 1)
      end

      it "returns false when daily kanji target has not been met yet" do
        refute users(:carl).has_reached_daily_kanji_target?
      end

      it "returns true when user has reached daily kanji target" do
        Kanji.create!(user: users(:carl), character: "寝", status: Kanji::ADDED_STATUS, added_to_list_at: Time.now.utc)
        assert users(:carl).has_reached_daily_kanji_target?
      end

      # To keep the flash message from continuing to show up if more kanji are added past the users target
      it "returns false when user has passed daily kanji target" do
        Kanji.create!(user: users(:carl), character: "寝", status: Kanji::ADDED_STATUS, added_to_list_at: Time.now.utc)
        Kanji.create!(user: users(:carl), character: "礼", status: Kanji::ADDED_STATUS, added_to_list_at: Time.now.utc)
        refute users(:carl).has_reached_daily_kanji_target?
      end
    end
  end

  describe "#has_reached_or_exceeded_daily_kanji_target?" do
    it "returns false when no daily kanji target is set" do
      refute users(:carl).has_reached_or_exceeded_daily_kanji_target?
    end

    describe "when daily kanji target is set" do
      setup do
        users(:carl).update!(daily_kanji_target: 1)
      end

      it "returns false when daily kanji target has not been met yet" do
        refute users(:carl).has_reached_or_exceeded_daily_kanji_target?
      end

      it "returns true when user has reached daily kanji target" do
        Kanji.create!(user: users(:carl), character: "寝", status: Kanji::ADDED_STATUS, added_to_list_at: Time.now.utc)
        assert users(:carl).has_reached_or_exceeded_daily_kanji_target?
      end

      it "returns true when user has passed daily kanji target" do
        Kanji.create!(user: users(:carl), character: "寝", status: Kanji::ADDED_STATUS, added_to_list_at: Time.now.utc)
        Kanji.create!(user: users(:carl), character: "礼", status: Kanji::ADDED_STATUS, added_to_list_at: Time.now.utc)
        assert users(:carl).has_reached_or_exceeded_daily_kanji_target?
      end
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
