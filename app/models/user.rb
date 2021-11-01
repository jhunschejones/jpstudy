class User < ApplicationRecord
  has_secure_password

  encrypts :name
  encrypts :email, deterministic: true, downcase: true

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :password, presence: true
  validates :username, presence: true, uniqueness: true

  has_many :words

  def subscription
    raise "Multiple matching subscriptions" if subscriptions.size > 1
    subscriptions.first
  end

  private

  def subscriptions
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

  def square_customer_id
    @square_customer_id ||= begin
      # https://github.com/square/square-ruby-sdk/blob/master/doc/api/customers.md#search-customers
      result = SQUARE_CLIENT
        .customers
        .search_customers(
          body: {
            query: {
              filter: {
                email_address: {
                  exact: email
                }
              }
            }
          }
        )
      raise "Square error #{result.errors.inspect}" if result.error?
      matching_square_customers = result.data.customers
      raise "Multiple matching customers" if matching_square_customers.size > 1
      matching_square_customers.first[:id]
    end
  end
end
