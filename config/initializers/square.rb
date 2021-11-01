SQUARE_CLIENT = Square::Client.new(
  access_token: ENV.fetch("SQUARE_ACCESS_TOKEN"),
  environment: "production"
)
