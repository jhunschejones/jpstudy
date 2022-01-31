require "active_support/core_ext/integer/time"
require "newrelic_rpm"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :purger
  # NOTE: The sassc-rails gem is automatically used for CSS compression if included
  #       in the Gemfile and no config.assets.css_compressor option is set.

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  config.action_cable.allowed_request_origins = [ "http://www.jpstudy.app/", "https://www.jpstudy.app/" ]
  config.web_socket_server_url = "wss://www.jpstudy.app/cable"

  config.session_store :cookie_store, expire_after: 14.days, key: "__Host-jpstudy_session", secure: Rails.env.production?

  config.action_dispatch.cookies_same_site_protection = :strict

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch(ENV["VIEW_CACHE_REDIS_URL"]),
    expires_in: 7.days,
    size: 25.megabytes
  }

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "jpstudy_production"

  config.action_mailer.perform_caching = false

  config.action_mailer.default_url_options = { host: "www.jpstudy.app", protocol: "https" }

  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_options = { from: "support@jpstudy.app" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: "email-smtp.us-east-1.amazonaws.com",
    port: 587,
    domain: "jpstudy.app",
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: "login",
    enable_starttls_auto: true,
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
    config.log_tags  = [ ENV["HEROKU_APP_NAME"] ] # using https://devcenter.heroku.com/articles/dyno-metadata
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

  config.active_record.encryption.primary_key = ENV.fetch("PRIMARY_KEY")
  config.active_record.encryption.deterministic_key = ENV.fetch("DETERMINISTIC_KEY")
  config.active_record.encryption.key_derivation_salt = ENV.fetch("KEY_DERIVATION_SALT")

  # https://blog.saeloun.com/2021/03/01/rails-6.1-adds-config-for-lazy-image-loading.html
  config.action_view.image_loading = "lazy"

  # Only affects displayed timezone, times are still stored in the DB as UTC
  config.time_zone = "Central Time (US & Canada)"
end
