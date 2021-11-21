class Word < ApplicationRecord
  validates :japanese, presence: true, uniqueness: { scope: [:english, :user], message: "+ English combination already exists" }
  validates :english, presence: true
  validates_presence_of :source_name, if: :source_reference?, message: "is required for source reference"
  validate :user_word_limit_not_exceeded, on: :create

  belongs_to :user, counter_cache: true

  scope :cards_not_created, -> { where(cards_created: false) }

  def added_to_list_on
    (added_to_list_at.present? ? added_to_list_at : created_at).strftime("%m/%d/%Y")
  end

  def cards_created_on
    cards_created_at.present? ? cards_created_at.strftime("%m/%d/%Y") : nil
  end

  private

  def user_word_limit_not_exceeded
    if user.has_reached_word_limit?
      errors.add(:user_word_limit, "exceeded")
    end
  end
end
