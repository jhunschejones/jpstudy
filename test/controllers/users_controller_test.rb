require "application_controller_test_case"

class UsersControllerTest < ApplicationControllerTestCase
  describe "#show" do
    it "loads the user details page for the current user" do
      login(users(:carl))
      get user_path(users(:carl))
      assert_response :success
      assert_select ".title", "User details"
    end

    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get user_path(users(:daisy))
      assert_response :not_found
    end

    describe "when the user does not have an active subscription" do
      it "shows the subscribe form" do
        login(users(:carl))
        get user_path(users(:carl))
        assert_select ".square .title", "Subscribe"
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

      teardown do
        SQUARE_CLIENT.unstub(:subscriptions)
      end

      it "shows the modify subscription form" do
        login(users(:carl))
        get user_path(users(:carl))
        assert_select ".square .title", "Manage your subscription"
      end
    end
  end

  describe "#new" do
    it "loads the signup form" do
      get signup_path
      assert_response :success
      assert_select ".title", "Sign up"
    end
  end

  describe "#edit" do
    it "returns the user edit form for the current user" do
      login(users(:carl))
      get edit_user_path(users(:carl))
      assert_response :success
      assert_select ".title", "Edit your user details"
    end

    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get edit_user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#create" do
    it "creates a new user" do
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
      last_email = ActionMailer::Base.deliveries.last
      assert_equal "Welcome to jpstudy", last_email.subject
      assert_equal ["jack@dafox.com"], last_email.to
    end

    describe "when max users is reached" do
      setup do
        @origional_max_users = ENV["MAX_USERS"]
        ENV["MAX_USERS"] = User.count.to_s
      end

      teardown do
        ENV["MAX_USERS"] = @origional_max_users
      end

      it "creates a new, unvalidated user" do
        assert_difference "User.count", 1 do
          post users_path, params: { user: { email: "jack@dafox.com", username: "jackthecat", name: "Jack", password: "super_secret", password_confirmation: "super_secret" } }
        end
        assert_equal "jackthecat", User.last.username
        assert_nil User.last.verification_sent_at
      end

      it "does not send a welcome email" do
        assert_no_emails do
          post users_path, params: { user: { email: "jack@dafox.com", username: "jackthecat", name: "Jack", password: "super_secret", password_confirmation: "super_secret" } }
        end
      end

      it "redirects to the login page with a message" do
        expected_message = "We are not accepting additional users for the alpha release at this time. We will contact you as soon as a spot opens."
        post users_path, params: { user: { email: "jack@dafox.com", username: "jackthecat", name: "Jack", password: "super_secret", password_confirmation: "super_secret" } }
        follow_redirect!
        assert_equal login_path, path
        assert_equal expected_message, flash[:alert]
      end
    end
  end

  describe "#update" do
    it "updates the current user" do
      login(users(:carl))
      assert_changes "User.find(users(:carl).id).name" do
        patch user_path(users(:carl)), params: { user: { name: "Carlus Foxus" } }
      end
      follow_redirect!
      assert_equal path, user_path(users(:carl))
    end

    it "returns not found when accessed by a different user" do
      login(users(:carl))
      assert_no_changes "User.find(users(:daisy).id).email" do
        patch user_path(users(:daisy)), params: { user: { email: "i_changed_your_email" } }
      end
      assert_response :not_found
    end

    describe "when updating the users email" do
      it "sets the unverified email" do
        login(users(:carl))
        assert_changes "User.find(users(:carl).id).unverified_email" do
          assert_no_changes "User.find(users(:carl).id).email" do
            patch user_path(users(:carl)), params: { user: { email: "new+carl@dafox.com" } }
          end
        end
        follow_redirect!
        assert_equal path, user_path(users(:carl))
        assert_equal "new+carl@dafox.com", users(:carl).reload.unverified_email
      end

      it "sends a user verification email" do
        login(users(:carl))
        assert_emails 1 do
          patch user_path(users(:carl)), params: { user: { email: "new+carl@dafox.com" } }
        end
        last_email = ActionMailer::Base.deliveries.last
        assert_equal "Welcome to jpstudy", last_email.subject
        assert_equal ["carl@dafox.com"], last_email.to
      end

      it "returns a message instructing the user to check their email" do
        expected_message = "Please follow the verification link sent to your new email to confirm the change"

        login(users(:carl))
        patch user_path(users(:carl)), params: { user: { email: "new+carl@dafox.com" } }
        follow_redirect!
        assert_equal expected_message, flash[:notice]
      end
    end
  end

  describe "#destroy" do
    it "deletes the user" do
      login(users(:carl))
      assert_difference "User.count", -1 do
        delete user_path(users(:carl))
      end
      assert_nil User.find_by(id: users(:carl).id), "user should have been deleted"
    end

    it "returns a confirmation message and logs the user out" do
      login(users(:carl))
      delete user_path(users(:carl))
      assert_equal "Your account has been deleted.", flash[:alert]
      assert_nil session[:session_token], "user should have been logged out"
    end

    it "returns not found when accessed by a different user" do
      login(users(:carl))
      assert_no_difference "User.count" do
        delete user_path(users(:daisy))
      end
      assert_response :not_found
    end
  end

  describe "#stats" do
    it "returns the user stats page for the current user" do
      login(users(:carl))
      get stats_user_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Your stats"
    end

    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get stats_user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#edit_targets" do
    it "returns the edit targets form for the current user" do
      login(users(:carl))
      get edit_targets_user_path(users(:carl))
      assert_response :success
      assert_select ".title", "Edit your target"
    end

    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get edit_targets_user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#before_you_go" do
    it "returns the user delete form for the current user" do
      login(users(:carl))
      get before_you_go_user_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Before you go..."
      assert_select "button", "Delete account"
    end

    it "returns not found when accessed by a different user" do
      login(users(:carl))
      get before_you_go_user_path(users(:daisy))
      assert_response :not_found
    end
  end

  describe "#in_out" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get in_out_user_path(users(:elemouse))
      assert_redirected_to user_path(users(:elemouse))
    end

    it "returns the words import export page" do
      login(users(:carl))
      get in_out_user_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Own your creations"
    end
  end
end
