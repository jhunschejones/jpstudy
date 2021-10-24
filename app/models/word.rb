class Word < ApplicationRecord
  validates :japanese, presence: true
  validates :english, presence: true
  validates_presence_of :source_name, :if => :source_reference?, message: "is required for source reference"
end
