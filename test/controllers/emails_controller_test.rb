require "application_controller_test_case"

class EmailsControllerTest < ApplicationControllerTestCase
  describe "#verify" do
    describe "with a valid token" do
      setup do
        @verification_token = VerificationToken.generate
        @new_email = "carl+updated@dafox.com"
        users(:carl).update!(
          unverified_email: @new_email,
          verification_digest: @verification_token.digest,
          verification_sent_at: Time.now.utc
        )
      end

      it "verifies and updates the user email" do
        get email_verify_path(token: @verification_token.to_s, username: users(:carl).username)

        assert_equal @new_email, users(:carl).reload.email
        assert_nil users(:carl).unverified_email
      end

      it "redirects to the login page with a message" do
        get email_verify_path(token: @verification_token.to_s, username: users(:carl).username)
        follow_redirect!

        assert_equal login_path, path
        assert_equal "Email successfully verified! Please log in to use your account.", flash[:success]
      end
    end

    describe "with an invalid token" do
      setup do
        @verification_token = VerificationToken.generate
        @another_token = VerificationToken.generate
        @new_email = "carl+updated@dafox.com"
        @previous_email = users(:carl).email
        users(:carl).update!(
          unverified_email: @new_email,
          verification_digest: @verification_token.digest,
          verification_sent_at: Time.now.utc
        )
      end

      it "does not verify and update the user email" do
        get email_verify_path(token: @another_token.to_s, username: users(:carl).username)

        assert_equal @previous_email, users(:carl).reload.email
        assert_equal @new_email, users(:carl).unverified_email
      end

      it "redirects to the login page with a message" do
        get email_verify_path(token: @another_token.to_s, username: users(:carl).username)
        follow_redirect!

        assert_equal login_path, path
        assert_equal "Invalid link. Use 'forgot password' to generate a new link.", flash[:alert]
      end
    end

    describe "with an expired token" do
      setup do
        @verification_token = VerificationToken.generate
        @new_email = "carl+updated@dafox.com"
        @previous_email = users(:carl).email
        users(:carl).update!(
          unverified_email: @new_email,
          verification_digest: @verification_token.digest,
          verification_sent_at: Time.now.utc - 6.hours
        )
      end

      it "does not verify and update the user email" do
        get email_verify_path(token: @verification_token.to_s, username: users(:carl).username)

        assert_equal @previous_email, users(:carl).reload.email
        assert_equal @new_email, users(:carl).unverified_email
      end

      it "redirects to the login page with a message" do
        get email_verify_path(token: @verification_token.to_s, username: users(:carl).username)
        follow_redirect!

        assert_equal login_path, path
        assert_equal "Invalid link. Use 'forgot password' to generate a new link.", flash[:alert]
      end
    end

    describe "with an invalid username" do
      setup do
        @verification_token = VerificationToken.generate
        @new_email = "carl+updated@dafox.com"
        @previous_email = users(:carl).email
        users(:carl).update!(
          unverified_email: @new_email,
          verification_digest: @verification_token.digest,
          verification_sent_at: Time.now.utc - 6.hours
        )
      end

      it "does not verify and update the user email" do
        get email_verify_path(token: @verification_token.to_s, username: "Jack")

        assert_equal @previous_email, users(:carl).reload.email
        assert_equal @new_email, users(:carl).unverified_email
      end

      it "redirects to the login page with a message" do
        get email_verify_path(token: @verification_token.to_s, username: "Jack")
        follow_redirect!

        assert_equal login_path, path
        assert_equal "Invalid link. Use 'forgot password' to generate a new link.", flash[:alert]
      end
    end
  end
end
