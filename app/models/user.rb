class User < ApplicationRecord
  has_secure_password

  encrypts :name
  encrypts :email, deterministic: true, downcase: true

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :password, presence: true, confirmation: true, length: { minimum: 12 }, if: :password
  validates :username, presence: true, uniqueness: true

  has_many :words, dependent: :destroy

  before_destroy :clean_up_square_data

  # specify which param is used for path helper methods
  def to_param
    username
  end

  # Returns false on failure
  def verify_email
    update(verified: true, verification_digest: nil, verified_at: Time.now.utc)
  end

  # Returns false on failure
  def reset_password(new_password)
    # In order to get a reset token, the user would have had to access their email,
    # thus, we can verify their email now as well if it wasn't already verified.
    unless self.verified?
      self.verified = true
      self.verification_digest = nil
      self.verified_at = Time.now.utc
    end
    self.reset_digest = nil
    self.password = new_password
    self.save
  end

  def active_subscription
    active_subscriptions = square_subscriptions.filter(&:active?)
    return nil if active_subscriptions.size.zero?
    if active_subscriptions.size > 1
      # TODO: what should we do with multiple active subscriptions?
    end
    active_subscriptions.first
  end

  private

  def square_subscriptions
    return [] if square_customer_id.nil?
    @subscriptions ||= begin
      # https://github.com/square/square-ruby-sdk/blob/master/doc/api/subscriptions.md#search-subscriptions
      result = SQUARE_CLIENT
        .subscriptions
        .search_subscriptions(
          body: {
            query: {
              filter: {
                customer_ids: [square_customer_id]
              }
            }
          }
        )
      raise "Square error #{result.errors.inspect}" if result.error?
      result
        .data
        .subscriptions
        .map { |subscription_props| Subscription.new(subscription_props) }
    end
  end

  def clean_up_square_data
    square_subscriptions.filter(&:active?).each do |subscription|
      result = SQUARE_CLIENT.subscriptions.cancel_subscription(subscription_id: subscription.id)
      raise "Square error #{result.errors.inspect}" if result.error?
    end
    result = SQUARE_CLIENT.customers.delete_customer(customer_id: square_customer_id)
    raise "Square error #{result.errors.inspect}" if result.error?
  end
end
