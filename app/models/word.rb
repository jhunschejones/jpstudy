class Word < ApplicationRecord
  validates :japanese, presence: true, uniqueness: { scope: [:english, :user] }
  validates :english, presence: true
  validates_presence_of :source_name, :if => :source_reference?, message: "is required for source reference"

  belongs_to :user

  scope :cards_not_created, -> { where(cards_created: false) }

  def added_on
    created_at.strftime("%m/%d/%Y")
  end
end
