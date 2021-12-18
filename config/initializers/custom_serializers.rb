require_relative "../../app/serializers/token_serializer"
require_relative "../../app/serializers/subscription_serializer"

Rails.application.config.active_job.custom_serializers += [
  TokenSerializer,
  SubscriptionSerializer
]
