require "application_controller_test_case"

class SessionsControllerTest < ApplicationControllerTestCase
  describe "#new" do
    it "returns the login page" do
      get login_path
      assert_response :success
      assert_select ".title", "Log in"
    end

    it "redirects users who are already logged in" do
      login(users(:carl))
      get login_path
      assert_redirected_to words_path(users(:carl))
    end

    it "adds the ref_id in the login form" do
      get login_path(ref_id: "heres-my-ref-id")
      assert_select "#ref_id" do
        assert_select "[value=?]", "heres-my-ref-id"
      end
    end

    it "adds the destination to the login form" do
      get login_path(destination: "words")
      assert_select "#destination" do
        assert_select "[value=?]", "words"
      end
    end

    it "shows predefined messages" do
      get login_path(message_id: "S01")
      assert_equal "🙏 Thank you for subscribing! Please follow the link in your email to finalize your subscription.", flash[:success]

      get login_path(message_id: "S02")
      assert_equal "Last step! Sign in to finish connecting your account to your shiny new subscription. ✨", flash[:success]

      get login_path(message_id: "E01")
      assert_equal "Email successfully verified! Please log in to use your account.", flash[:success]
    end
  end

  describe "#create" do
    it "logs a user in" do
      post login_path, params: { email: users(:carl).email, password: "secret_secret" }
      follow_redirect!
      assert_equal words_path(users(:carl)), path
    end

    it "sets the square_customer_id when param is present and valid" do
      square_customer_id = "square_customer_id_1"
      encrypted_square_customer_id = UserMailer.new.send(:encrypt, square_customer_id)
      assert_changes "User.find(users(:carl).id).square_customer_id" do
        post login_path, params: {
          email: users(:carl).email,
          password: "secret_secret",
          ref_id: encrypted_square_customer_id
        }
      end
      assert_equal square_customer_id, users(:carl).reload.square_customer_id
    end

    it "does not set the square_customer_id when param is present but invalid" do
      assert_no_changes "User.find(users(:carl).id).square_customer_id" do
        post login_path, params: {
          email: users(:carl).email,
          password: "secret_secret",
          ref_id: "trying_to_hack_your_account"
        }
      end
    end

    it "redirects to pre-determined paths" do
      post login_path, params: { email: users(:carl).email, password: "secret_secret", destination: "R01" }
      assert_redirected_to words_path(users(:carl))

      post login_path, params: { email: users(:carl).email, password: "secret_secret", destination: "R02" }
      assert_redirected_to next_kanji_path(users(:carl))

      post login_path, params: { email: users(:carl).email, password: "secret_secret", destination: "R03" }
      assert_redirected_to search_words_path(users(:carl))

      post login_path, params: { email: users(:carl).email, password: "secret_secret", destination: "R04" }
      assert_redirected_to stats_user_path(users(:carl))

      post login_path, params: { email: users(:carl).email, password: "secret_secret", destination: "R05" }
      assert_redirected_to in_out_user_path(users(:carl))

      post login_path, params: { email: users(:carl).email, password: "secret_secret", destination: "R06" }
      assert_redirected_to user_path(users(:carl))

      post login_path, params: { email: users(:carl).email, password: "secret_secret", destination: "R07" }
      assert_redirected_to memos_path(users(:carl))
    end

    it "protects against brute force attacks" do
      Rails.stubs(:cache).returns(ActiveSupport::Cache.lookup_store(:memory_store))
      Rails.cache.clear

      9.times do
        post login_path, params: { email: users(:carl).email, password: "wrong_password" }
      end
      post login_path, params: { email: users(:carl).email, password: "wrong_password" }
      follow_redirect!
      assert_equal login_path, path
      assert_equal "Maximum login attempts exceeded. Please try again in 15 minutes.", flash[:alert]
    end
  end

  describe "#destroy" do
    it "logs a user out" do
      login(users(:carl))
      delete logout_path
      follow_redirect!
      assert_equal "Succesfully logged out. またね！", flash[:notice]
      assert_equal login_path, path
    end
  end
end
