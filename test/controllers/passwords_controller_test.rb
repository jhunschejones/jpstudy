require "application_controller_test_case"

class PasswordsControllerTest < ApplicationControllerTestCase
  describe "#forgot_form" do
    it "redirects users who are already logged in" do
      login(users(:carl))
      get password_forgot_path
      assert_redirected_to user_path(users(:carl))
    end

    it "returns the forgot password form" do
      get password_forgot_path
      assert_response :success
    end
  end

  describe "#reset_form" do
    it "redirects users who are already logged in" do
      login(users(:carl))
      get password_reset_path
      assert_redirected_to user_path(users(:carl))
    end

    it "returns the password reset form" do
      get password_reset_path
      assert_response :success
    end
  end

  describe "#forgot" do
    describe "if a user exists for the given email" do
      it "sends a password reset email" do
        assert_emails 1 do
          post password_forgot_path, params: { email: users(:carl).email }
        end
        last_email = ActionMailer::Base.deliveries.last
        assert_equal "Password reset request", last_email.subject
        assert_equal [users(:carl).email], last_email.to
      end

      it "redirects to the login page with a message" do
        post password_forgot_path, params: { email: users(:carl).email }
        follow_redirect!
        assert_equal login_path, path
        assert_equal "Please check your email for a password reset link", flash[:notice]
      end
    end

    describe "if no user exists for the given email" do
      it "does not send a password reset email" do
        assert_no_emails do
          post password_forgot_path, params: { email: "suspicious@dafox.com" }
        end
      end

      it "redirects to the login page without telling the user the email was not found" do
        post password_forgot_path, params: { email: "suspicious@dafox.com" }
        follow_redirect!
        assert_equal login_path, path
        assert_equal "Please check your email for a password reset link", flash[:notice]
      end
    end
  end

  describe "#reset" do
    it "updates the users password" do
      token = ResetToken.generate
      users(:carl).update!(
        reset_sent_at: Time.now.utc,
        reset_digest: token.digest
      )
      assert_changes "User.find(users(:carl).id).password_digest" do
        post password_reset_path, params: { token: token, username: users(:carl).username, email: users(:carl).email, password: "even_more_s3cure", password_confirmation: "even_more_s3cure" }
      end
    end

    it "redirects to the login page with a message" do
      token = ResetToken.generate
      users(:carl).update!(
        reset_sent_at: Time.now.utc,
        reset_digest: token.digest
      )
      post password_reset_path, params: { token: token, username: users(:carl).username, email: users(:carl).email, password: "even_more_s3cure", password_confirmation: "even_more_s3cure" }
      follow_redirect!
      assert_equal login_path, path
      assert_equal "Password successfully reset! Please log in with your new password.", flash[:success]
    end

    describe "when the token is invalid" do
      it "does not update the users password" do
        assert_no_changes "User.find(users(:carl).id).password_digest" do
          post password_reset_path, params: { token: "bad-token", username: users(:carl).username, email: users(:carl).email, password: "even_more_s3cure", password_confirmation: "even_more_s3cure" }
        end
      end

      it "redirects to the login page with a message" do
        post password_reset_path, params: { token: "bad-token", username: users(:carl).username, email: users(:carl).email, password: "even_more_s3cure", password_confirmation: "even_more_s3cure" }
        follow_redirect!
        assert_equal login_path, path
        assert_equal "Invalid or expired link. Please check your email or generate a new link.", flash[:alert]
      end
    end
  end
end
