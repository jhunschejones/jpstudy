require "test_helper"

class ApplicationControllerTestCase < ActionDispatch::IntegrationTest
  def login(user)
    post login_path, params: { email: user.email, password: "secret_secret" }
  end
end
