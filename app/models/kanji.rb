class Kanji < ApplicationRecord
  ADDED_STATUS = "added".freeze
  SKIPPED_STATUS = "skipped".freeze
  KANJI_REGEX = /[一-龯]/

  belongs_to :user, counter_cache: true
  validates :character, presence: true, uniqueness: true, format: { with: KANJI_REGEX }

  def self.new_for(user:)
    all_kanjis_in_words = user.words.pluck(:japanese)
      .flat_map { |word| word.split("") }
      .uniq
      .select { |kanji| kanji =~ KANJI_REGEX }
    all_kanjis_in_words - user.kanjis.pluck(:character)
  end

  # Word.where("japanese ~ ?", "^[一-龯]$").to_sql
  # ActiveRecord::Base.connection.execute("SELECT ARRAY(SELECT DISTINCT c FROM unnest(string_to_array(japanese, null)) AS a(c)) FROM words;").to_a

  # === First working block of text
  # ActiveRecord::Base.connection.execute("SELECT string_agg(c, '') FROM (SELECT DISTINCT regexp_split_to_table(lower(japanese), '') as c from words) t;").first["string_agg"]

  # === Second working block of text, more performant
  # ActiveRecord::Base.connection.execute("SELECT string_agg(c, '') FROM (SELECT DISTINCT unnest(string_to_array(japanese, null)) AS c FROM words) t;").first["string_agg"]

  # ActiveRecord::Base.connection.execute("SELECT * FROM (SELECT DISTINCT unnest(string_to_array(japanese, null)) FROM words) t;").to_a

  # === RUBY WAY ===
  # All kanjis:
  # Word.pluck(:japanese)
  #     .flat_map { |word| word.split("") }
  #     .uniq
  #     .select { |kanji| kanji =~ Kanji::KANJI_REGEX }

  # All _new_ kanjis:
  # Word.pluck(:japanese).flat_map { |word| word.split("") }.uniq.select { |kanji| kanji =~ Kanji::KANJI_REGEX } - Kanji.pluck(:character)
end
