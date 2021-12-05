source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.3"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.0.alpha2"

gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "redis", "~> 4.0"

gem "bcrypt", "~> 3.1.7"

gem "importmap-rails", "0.9.1" # avoiding an issue for Safari in 0.9.2 that's not quite fixed yet in 0.9.3 https://github.com/rails/importmap-rails/releases
gem "turbo-rails", "~> 0.9"
gem "stimulus-rails", "~> 0.7"
gem "sassc-rails", "~> 2.1"
gem "heroicon"

gem "square.rb"

gem "bootsnap", ">= 1.4.4", require: false

group :development, :test do
  # Start debugger with binding.b [https://github.com/ruby/debug]
  gem "debug", ">= 1.0.0", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console", ">= 4.1.0"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "minitest-spec-rails"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
