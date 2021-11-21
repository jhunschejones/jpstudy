require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by(
    :selenium,
    using: ENV["USE_HEADFULL_BROWSER"] ? :chrome : :headless_chrome,
    screen_size: [1000, 1000]
  )

  def login(user)
    visit login_url
    fill_in "Email", with: user.email
    fill_in "Password", with: "secret_secret"
    click_on "Log in"
  end
end
