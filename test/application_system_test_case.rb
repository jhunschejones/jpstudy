require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["USE_HEADFULL_BROWSER"]
    driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  else
    driven_by :selenium, using: :headless_chrome
  end

  def login(user)
    visit login_url
    fill_in "Email", with: user.email
    fill_in "Password", with: "secret_secret"
    click_on "Log in"
  end
end
