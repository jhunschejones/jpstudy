class Word < ApplicationRecord
  include PageOutdatedNotifiable

  validates :japanese, presence: true, uniqueness: { scope: [:english, :user], message: "+ English combination already exists" }
  validates :english, presence: true
  validates_presence_of :source_name, if: :source_reference?, message: "is required for source reference"
  validate :user_word_limit_not_exceeded, on: :create

  belongs_to :user, counter_cache: true, inverse_of: :words

  scope :cards_not_created, -> { where(cards_created: false) }

  after_create_commit {
    notify_outdated_word_list_pages
    notify_outdated_next_kanji_pages
  }
  after_update_commit {
    notify_outdated_word_list_pages
    notify_outdated_next_kanji_pages
  }
  after_destroy_commit {
    notify_outdated_word_list_pages(async: false)
    notify_outdated_next_kanji_pages(async: false)
  }

  def added_to_list_on
    (added_to_list_at.present? ? added_to_list_at : created_at).strftime("%m/%d/%Y")
  end

  def cards_created_on
    cards_created_at.presence && cards_created_at.strftime("%m/%d/%Y")
  end

  private

  def user_word_limit_not_exceeded
    if user.has_reached_word_limit?
      errors.add(:user_word_limit, "exceeded")
    end
  end
end
