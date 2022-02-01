class Kanji < ApplicationRecord
  include PageOutdatedNotifiable
  self.table_name = "kanji" # otherwise ActiveRecord looks for a 'kanjis' table

  VALID_STATUSES = [
    ADDED_STATUS = "added".freeze,
    SKIPPED_STATUS = "skipped".freeze
  ]
  KANJI_REGEX = /[一-龯]/

  belongs_to :user, counter_cache: :kanji_count, inverse_of: :kanji
  validates :character, presence: true, uniqueness: true, format: { with: KANJI_REGEX }
  validates :status, allow_nil: true, inclusion: { in: VALID_STATUSES, message: "status must be either '#{VALID_STATUSES.join("', or '")}'" }
  validate :user_kanji_limit_not_exceeded, on: :create

  scope :added, -> { where(status: ADDED_STATUS) }

  after_create_commit { notify_outdated_next_kanji_pages }
  after_update_commit { notify_outdated_next_kanji_pages }
  after_destroy_commit { notify_outdated_next_kanji_pages(async: false) }

  def self.all_new_for(user:)
    all_kanji_in_words = user.words
      .order(added_to_list_at: :asc)
      .order(created_at: :asc)
      .pluck(:japanese)
      .flat_map(&:chars)
      .uniq
      .select { |character| character =~ KANJI_REGEX }
    (
      all_kanji_in_words - user.kanji.pluck(:character)
    ).map { |character| new(character: character) }
  end

  def self.next_new_for(user:)
    all_new_for(user: user).first
  end

  def added_to_list_on
    (added_to_list_at.present? ? added_to_list_at : created_at).strftime("%m/%d/%Y")
  end

  private

  def user_kanji_limit_not_exceeded
    if user.has_reached_kanji_limit?
      errors.add(:user_kanji_limit, "exceeded")
    end
  end
end
