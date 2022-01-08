# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :verification_digest, :reset_digest, :email, :password, :name
]

# it's okay to log these parameters
Rails.application.config.filter_parameters -= [:source_name, :username]
