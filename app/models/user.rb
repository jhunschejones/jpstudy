class User < ApplicationRecord
  # Don't show these attributes in logs
  self.filter_attributes = [
    :password,
    :verification_digest,
    :reset_digest,
    :session_token
  ]
  include Hashid::Rails

  VALID_USER_ROLES = [
    USER_ROLE = "user",
    ADMIN_ROLE = "admin"
  ]
  DEFAULT_WORD_LIMIT = 1000
  DEFAULT_KANJI_LIMIT = 1000
  MAX_MONTHLY_AUDIO_CONVERSIONS = 500

  has_secure_password

  encrypts :name
  encrypts :email, deterministic: true, downcase: true

  validates :email, presence: true, uniqueness: true
  validates :session_token, allow_nil: true, uniqueness: true
  validates :name, presence: true
  validates :password, presence: true, confirmation: true, length: { minimum: 12 }, if: :password
  validates :username, presence: true, uniqueness: true, length: { minimum: 1, maximum: 39 }, format: { with: /\A[a-zA-Z0-9]+\z/, message: "can only contain letters and numbers" }
  validates :role, inclusion: { in: VALID_USER_ROLES, message: "must be one of [#{VALID_USER_ROLES.join(", ")}]" }

  has_many :words, dependent: :delete_all, inverse_of: :user
  has_many :kanji, dependent: :delete_all, inverse_of: :user
  has_many :memos, dependent: :delete_all, inverse_of: :user

  before_destroy :clean_up_square_data

  # specify which param is used for path helper methods
  def to_param
    username
  end

  # Returns false on failure
  def verify_email
    update(verified: true, verification_digest: nil, verified_at: Time.now.utc)
  end

  def trial_active?
    return false if trial_ends_at.nil?
    trial_ends_at.utc > Time.now.utc
  end

  def can_add_more_words?
    return true unless word_limit
    # calling `words.size` here uses the counter_cache instead of making an extra query
    words.size + 1 <= word_limit
  end

  def can_add_more_kanji?
    return true unless kanji_limit
    kanji.size + 1 <= kanji_limit
  end

  def can_do_more_audio_conversions?
    audio_conversions_used_this_month < MAX_MONTHLY_AUDIO_CONVERSIONS
  end

  def has_reached_daily_word_target?
    daily_word_target.presence && words.where(checked_at: Date.today.all_day).size == daily_word_target
  end

  def has_reached_or_exceeded_daily_word_target?
    daily_word_target.presence && words.where(checked_at: Date.today.all_day).size >= daily_word_target
  end

  def has_reached_daily_kanji_target?
    daily_kanji_target.presence && kanji.added.where(added_to_list_at: Date.today.all_day).size == daily_kanji_target
  end

  def has_reached_or_exceeded_daily_kanji_target?
    daily_kanji_target.presence && kanji.added.where(added_to_list_at: Date.today.all_day).size >= daily_kanji_target
  end

  def can_access_admin_tools?
    role == ADMIN_ROLE && ENV["HEROKU_SLUG_COMMIT"] && ENV["HEROKU_RELEASE_CREATED_AT"]
  end

  # Returns false on failure
  def reset_password(new_password)
    # In order to get a reset token, the user would have had to access their email,
    # thus, we can verify their email now as well if it wasn't already verified.
    unless verified?
      self.verified = true
      self.verification_digest = nil
      self.verified_at = Time.now.utc
    end
    self.reset_digest = nil
    self.password = new_password
    save
  end

  def active_subscription
    active_subscriptions = square_subscriptions.filter(&:active?)
    return nil if active_subscriptions.size.zero?
    if active_subscriptions.size > 1
      # TODO: what should we do with multiple active subscriptions?
    end
    active_subscriptions.first
  end

  def clear_square_subscriptions_cache
    Rails.cache.delete(square_subscriptions_cache_key)
  end

  def words_stream_name
    "user_#{hashid}_words"
  end

  def kanji_stream_name
    "user_#{hashid}_kanji"
  end

  def can_modify_resources_belonging_to?(resource_owner)
    return false if resource_owner.nil?
    self == resource_owner
  end

  def has_set_resource_as_public?(resource_name)
    # This is where logic will live for resource sharing (READ) permissions.
    #
    # So far the possible values for `resource_name` are `:kanji`, `:words`,
    # `:memos` and `:stats`.
    #
    # NOTE: remove public routes from the `secure_behind_subscription` before_filter
    # when enabling this feature
    false
  end

  private

  def square_subscriptions(revalidate_at: Time.now.utc.tomorrow)
    return [] if square_customer_id.nil?
    expires_in = (revalidate_at - Time.now.utc).to_i.seconds # a negative value here will be a cache miss
    Rails.cache.fetch(square_subscriptions_cache_key, expires_in: expires_in, force: !(Rails.configuration.cache_classes || ENV["VERY_CACHE"])) do
      Rails.logger.info("#{square_subscriptions_cache_key} :: cache miss")
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
  end

  def square_subscriptions_cache_key
    @square_subscriptions_cache_key ||= "#{username}/square_subscriptions"
  end

  def clean_up_square_data
    square_subscriptions.filter(&:active?).each do |subscription|
      result = SQUARE_CLIENT.subscriptions.cancel_subscription(subscription_id: subscription.id)
      raise "Square error #{result.errors.inspect}" if result.error?
    end
    if square_customer_id
      result = SQUARE_CLIENT.customers.delete_customer(customer_id: square_customer_id)
      raise "Square error #{result.errors.inspect}" if result.error?
    end
    clear_square_subscriptions_cache
  end
end
