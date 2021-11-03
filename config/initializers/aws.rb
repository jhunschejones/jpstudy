Aws::Rails.add_action_mailer_delivery_method(
  :amazon_ses,
  credentials: Aws::Credentials.new(
    ENV["AWS_ACCESS_KEY_ID"],
    ENV["AWS_SECRET_ACCESS_KEY"]
  ),
  region: ENV["AWS_REGION"]
)
