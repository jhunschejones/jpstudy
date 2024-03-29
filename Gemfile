source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.0.rc1"

gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "redis", "~> 4.0"

gem "bcrypt", "~> 3.1.7"

gem "importmap-rails", "~> 1.0"
gem "turbo-rails", "~> 1.0"
gem "stimulus-rails", "~> 1.0"
gem "sassc-rails", "~> 2.1"
gem "heroicon"

gem "square.rb"
gem "aws-sdk-polly"
gem "aws-sdk-s3"
gem "hashid-rails"
gem "newrelic_rpm"

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
  gem "mocha"
  gem "database_cleaner"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
