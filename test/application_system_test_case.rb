require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  TURBO_WAIT_SECONDS = 0.1 # wait for page to update with turbo_stream

  driven_by(
    :selenium,
    using: ENV["USE_HEADFULL_BROWSER"] ? :chrome : :headless_chrome,
    screen_size: [1024, 768]
  )

  def login(user)
    visit login_url
    fill_in "Email", with: user.email
    fill_in "Password", with: "secret_secret"
    click_on "Log in"
    page.driver.browser.manage.add_cookie(name: "username", value: signed_username(user.username))
  end

  def signed_username(username)
    # https://www.rubydoc.info/docs/rails/4.1.7/ActionDispatch/Cookies/CookieJar#initialize-instance_method
    # https://stackoverflow.com/questions/43690796/setup-cookie-signed-in-rails-5-controller-integration-tests
    cookie_jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    cookie_jar.signed["username"] = { value: username }
    Rack::Utils.escape(cookie_jar["username"])
  end
end
