require "application_controller_test_case"

class UsersControllerTest < ApplicationControllerTestCase
  describe "#show" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#new" do
  end

  describe "#edit" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get edit_user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#create" do
  end

  describe "#update" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      patch user_path(users(:daisy)), params: { user: { email: "i_changed_your_email" } }
      assert_response :not_found
    end
  end

  describe "#destroy" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      delete user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#stats" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get stats_user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#edit_targets" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get edit_targets_user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#before_you_go" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get before_you_go_user_path(users(:daisy))
      assert_response :not_found
    end
  end
end
