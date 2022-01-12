require "application_controller_test_case"

class SessionsControllerTest < ApplicationControllerTestCase
  it "logs a user in" do
    https!
    get login_path
    assert_response :success

    post login_path, params: { email: users(:carl).email, password: "secret_secret" }
    follow_redirect!
    assert_equal words_path, path
  end

  it "logs a user out" do
    login(users(:carl))
    delete logout_path
    follow_redirect!
    assert_equal "Succesfully logged out. またね！", flash[:notice]
    assert_equal login_path, path
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
