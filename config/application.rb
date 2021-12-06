require_relative "boot"

require "rails/all"
require "newrelic_rpm"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Jpstudy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # https://docs.newrelic.com/docs/logs/logs-context/configure-logs-context-ruby/#enable-rails
    config.log_formatter = ::NewRelic::Agent::Logging::DecoratingFormatter.new
  end
end
