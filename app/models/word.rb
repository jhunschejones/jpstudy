class Word < ApplicationRecord
  validates :japanese, presence: true, uniqueness: { scope: [:english, :user], message: "+ English combination already exists" }
  validates :english, presence: true
  validates_presence_of :source_name, if: :source_reference?, message: "is required for source reference"
  validate :user_word_limit_not_exceeded, on: :create

  belongs_to :user, counter_cache: true, inverse_of: :words

  scope :cards_not_created, -> { where(cards_created: false) }

  after_create_commit {
    broadcast_prepend_later_to(user.words_stream_name, target: "words_1", locals: { apply_js_filters: true })
    broadcast_replace_later_to(user.kanji_stream_name, target: "flashes", partial: "flashes", locals: { flash: { notice: "This page is now out of date. Please refresh to see your newest kanji!" } })
  }
  after_update_commit {
    broadcast_replace_later_to(user.words_stream_name, locals: { apply_js_filters: true })
    broadcast_replace_later_to(user.kanji_stream_name, target: "flashes", partial: "flashes", locals: { flash: { notice: "This page is now out of date. Please refresh to see your newest kanji!" } })
  }
  after_destroy_commit {
    broadcast_remove_to(user.words_stream_name)
    broadcast_replace_to(user.kanji_stream_name, target: "flashes", partial: "flashes", locals: { flash: { notice: "This page is now out of date. Please refresh to see your newest kanji!" } })
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
