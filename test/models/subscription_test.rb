require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  describe "#self_management_link" do
    it "returns expected link format" do
      expected_link = "https://squareup.com/buyer-subscriptions/manage?buyer_management_token=my-token"
      subscription = Subscription.new(
        buyer_self_management_token: "my-token",
        start_date: Time.now.to_s,
        charged_through_date: (Time.now + 14.days).to_s
      )
      assert_equal expected_link, subscription.self_management_link
    end
  end

  describe "#active?" do
    it "returns true for active status" do
      subscription = Subscription.new(
        status: "ACTIVE",
        start_date: Time.now.to_s,
        charged_through_date: (Time.now + 14.days).to_s
      )
      assert subscription.active?
    end

    it "returns false for all other statuses" do
      subscription = Subscription.new(
        status: "CANCELLED",
        start_date: Time.now.to_s,
        charged_through_date: (Time.now + 14.days).to_s
      )
      refute subscription.active?
    end
  end
end
