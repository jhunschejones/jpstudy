class Word < ApplicationRecord
  validates :japanese, presence: true
  validates :english, presence: true
end
