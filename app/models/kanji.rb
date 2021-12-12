class Kanji < ApplicationRecord
  self.table_name = "kanji" # otherwise ActiveRecord looks for a 'kanjis' table

  ADDED_STATUS = "added".freeze
  SKIPPED_STATUS = "skipped".freeze
  KANJI_REGEX = /[一-龯]/

  belongs_to :user, counter_cache: true
  validates :character, presence: true, uniqueness: true, format: { with: KANJI_REGEX }

  def self.all_new_for(user:)
    all_kanji_in_words = user.words.pluck(:japanese)
      .flat_map { |word| word.split("") }
      .uniq
      .select { |character| character =~ KANJI_REGEX }
    all_kanji_in_words - user.kanji.pluck(:character)
  end

  def self.next_for(user:)
    all_new_for(user: user).first
  end
end
