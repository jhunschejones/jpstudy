class Word < ApplicationRecord
  validates :japanese, presence: true, uniqueness: { scope: [:english, :user], message: "+ English combination already exists" }
  validates :english, presence: true
  validates_presence_of :source_name, :if => :source_reference?, message: "is required for source reference"
  validate :user_word_limit_not_exceeded, on: :create

  belongs_to :user, counter_cache: true

  scope :cards_not_created, -> { where(cards_created: false) }

  def added_to_list_on
    (added_to_list_at.present? ? added_to_list_at : created_at).strftime("%m/%d/%Y")
  end

  private

  def user_word_limit_not_exceeded
    # calling `user.words.size` here means we use the counter_cache instead of making an extra query
    if user.word_limit && user.words.size >= user.word_limit
      errors.add(:user_word_limit, "exceeded")
    end
  end
end
