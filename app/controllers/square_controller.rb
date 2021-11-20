class SquareController < ApplicationController
  skip_before_action :authenticate_user
  skip_before_action :verify_authenticity_token
  before_action :validate_webhook, except: [:logout]

  def subscription_created
    # https://developer.squareup.com/reference/square/webhooks/subscription.created
    # 1. Get customer_id out of the order body
    customer_id = params.dig("data", "object", "subscription", "customer_id")
    # 2. Look up the customer in Square to get their :email_address
    # https://github.com/square/square-ruby-sdk/blob/master/doc/api/customers.md#search-customers
    result = SQUARE_CLIENT.customers.retrieve_customer(customer_id: customer_id)
    raise "Square error #{result.errors.inspect}" if result.error?
    billing_email = result.data.customer[:email_address]
    # 3. TODO: Send the user an email to link their subscription to their account
    #    Email should include a link to the login page along with a param that is an encrypted customer ID
    #    Singining in with the param present should un-encrypt the ID, verify it is valid, then assign it to that user
    UserMailer
      .with(square_customer_id: customer_id, email: billing_email)
      .confirm_subscription_email
      .deliver_later

    head :ok
  end

  def subscription_updated
    # customer_id should stay the same, we probably don't need to listen to these?
  end

  # Special redirect link for Square to send users to after checking out
  def logout
    reset_session
    redirect_to login_url(message_id: "S01")
  end

  private

  def validate_webhook
    # https://developer.squareup.com/docs/webhooks/step3validate
    string_to_sign = "#{request.url}#{request.raw_post}"
    header_signature = request.headers["X-Square-Signature"]
    digest = OpenSSL::Digest.new("sha1")
    hmac = OpenSSL::HMAC.digest(digest, ENV.fetch("SQUARE_WEBHOOK_SIGNATURE_KEY"), string_to_sign)
    hmac_64 = Base64.encode64(hmac).strip

    if header_signature != hmac_64
      return head :forbidden
    end
  end
end
