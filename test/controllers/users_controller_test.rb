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
    it "loads the signup form" do
      get signup_path
      assert_response :success
      assert_select "h2.title", "Sign up"
    end
  end

  describe "#edit" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get edit_user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#create" do
    it "creates a user" do
      assert_difference "User.count", 1 do
        post users_path, params: { user: { email: "jack@dafox.com", username: "jackthecat", name: "Jack", password: "super_secret", password_confirmation: "super_secret" } }
      end
      assert_equal "jackthecat", User.last.username
      assert_redirected_to login_url
    end

    it "sends a welcome email to the new user" do
      assert_emails 1 do
        post users_path, params: { user: { email: "jack@dafox.com", username: "jackthecat", name: "Jack", password: "super_secret", password_confirmation: "super_secret" } }
      end
      last_email  = ActionMailer::Base.deliveries.last
      assert_equal "Welcome to jpstudy", last_email.subject
      assert_equal ["jack@dafox.com"], last_email.to
    end
  end

  describe "#update" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      assert_no_changes "User.find(users(:daisy).id).email" do
        patch user_path(users(:daisy)), params: { user: { email: "i_changed_your_email" } }
      end
      assert_response :not_found
    end
  end

  describe "#destroy" do
    it "returns not found when accessed by a different user" do
      login(users(:carl))
      assert_no_difference "User.count" do
        delete user_path(users(:daisy))
      end
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
