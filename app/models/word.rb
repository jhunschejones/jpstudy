class Word < ApplicationRecord
  include PageOutdatedNotifiable

  validates :japanese, presence: true, uniqueness: { scope: [:english, :user], message: "+ English combination already exists" }
  validates :english, presence: true
  validates_presence_of :source_name, if: :source_reference?, message: "is required for source reference"
  validate :user_word_limit_not_exceeded, on: :create

  belongs_to :user, counter_cache: true, inverse_of: :words

  scope :not_checked, -> { where(checked: false) }

  after_create_commit { notify_socket_subscribers(async: true) }
  after_update_commit { notify_socket_subscribers(async: true) }
  after_destroy_commit { notify_socket_subscribers(async: false) }

  attr_accessor :skip_turbostream_callbacks

  def added_to_list_on
    (added_to_list_at.present? ? added_to_list_at : created_at).strftime("%m/%d/%Y")
  end

  def checked_on
    checked_at.presence && checked_at.strftime("%m/%d/%Y")
  end

  private

  def user_word_limit_not_exceeded
    unless user.reload.can_add_more_words?
      errors.add(:user_word_limit, "exceeded")
    end
  end

  def notify_socket_subscribers(async: true)
    unless skip_turbostream_callbacks
      notify_outdated_word_list_pages(async: async)
      notify_outdated_next_kanji_pages(async: async)
    end
  end
end
