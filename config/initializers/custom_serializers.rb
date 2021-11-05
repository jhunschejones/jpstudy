require_relative "../../app/serializers/token_serializer"

Rails.application.config.active_job.custom_serializers << TokenSerializer
