class Word < ApplicationRecord
  TURBO_STREAM_DELAY = 2.seconds

  validates :japanese, presence: true, uniqueness: { scope: [:english, :user], message: "+ English combination already exists" }
  validates :english, presence: true
  validates_presence_of :source_name, if: :source_reference?, message: "is required for source reference"
  validate :user_word_limit_not_exceeded, on: :create

  belongs_to :user, counter_cache: true, inverse_of: :words

  scope :cards_not_created, -> { where(cards_created: false) }

  after_create_commit {
    broadcast_replace_later_to(user.words_stream_name, target: "page-outdated", partial: "page_outdated", locals: { visible: true, last_update: (Time.now - TURBO_STREAM_DELAY).utc, target_selector: ".word_#{id}" })
    broadcast_replace_later_to(user.kanji_stream_name, target: "page-outdated", partial: "page_outdated", locals: { visible: true, last_update: (Time.now - TURBO_STREAM_DELAY).utc, target_selector: ".next-kanji-page" })
  }
  after_update_commit {
    broadcast_replace_later_to(user.words_stream_name, target: "page-outdated", partial: "page_outdated", locals: { visible: true, last_update: (Time.now - TURBO_STREAM_DELAY).utc, target_selector: ".word_#{id}" })
    broadcast_replace_later_to(user.kanji_stream_name, target: "page-outdated", partial: "page_outdated", locals: { visible: true, last_update: (Time.now - TURBO_STREAM_DELAY).utc, target_selector: ".next-kanji-page" })
  }
  after_destroy_commit {
    broadcast_replace_to(user.words_stream_name, target: "page-outdated", partial: "page_outdated", locals: { visible: true, last_update: (Time.now - TURBO_STREAM_DELAY).utc, target_selector: ".word_#{id}" })
    broadcast_replace_to(user.kanji_stream_name, target: "page-outdated", partial: "page_outdated", locals: { visible: true, last_update: (Time.now - TURBO_STREAM_DELAY).utc, target_selector: ".next-kanji-page" })
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
