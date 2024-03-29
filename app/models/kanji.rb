class Kanji < ApplicationRecord
  include PageOutdatedNotifiable
  self.table_name = "kanji" # otherwise ActiveRecord looks for a 'kanjis' table

  VALID_STATUSES = [
    NEW_STATUS = "new".freeze,
    ADDED_STATUS = "added".freeze,
    SKIPPED_STATUS = "skipped".freeze
  ]
  KANJI_REGEX = /[一-龯]/

  belongs_to :user, counter_cache: :kanji_count, inverse_of: :kanji
  validates :character, presence: true, uniqueness: { scope: [:character, :user] }, format: { with: KANJI_REGEX }
  validates :status, inclusion: { in: VALID_STATUSES, message: "must be one of '#{VALID_STATUSES.join(", ")}'" }
  validate :user_kanji_limit_not_exceeded, on: :create

  scope :new_status, -> { where(status: NEW_STATUS) }
  scope :added, -> { where(status: ADDED_STATUS) }
  scope :skipped, -> { where(status: SKIPPED_STATUS) }
  scope :skipped_or_added, -> { where(status: [ADDED_STATUS, SKIPPED_STATUS]) }

  after_create_commit { notify_socket_subscribers(async: true) }
  after_update_commit { notify_socket_subscribers(async: true) }
  after_destroy_commit { notify_socket_subscribers(async: false) }

  attr_accessor :skip_turbostream_callbacks

  def self.all_new_characters_for(user:)
    added_or_skipped = user.kanji.skipped_or_added.pluck(:character)
    new_in_db = user.kanji
      .new_status
      .order(created_at: :asc, updated_at: :desc)
      .pluck(:character)
    new_in_words = user.words
      .order(added_to_list_at: :asc, created_at: :asc)
      .pluck(:japanese)
      .flat_map(&:chars)
      .uniq
      .select { |character| character =~ KANJI_REGEX }

    new_in_words.union(new_in_db) - added_or_skipped
  end

  def self.next_new_for(user:)
    next_new_character = all_new_characters_for(user: user).first
    return nil unless next_new_character
    user.kanji.new_status.find_by(character: next_new_character) || new(character: next_new_character)
  end

  def added_to_list_on
    (added_to_list_at.present? ? added_to_list_at : created_at).strftime("%m/%d/%Y")
  end

  private

  def user_kanji_limit_not_exceeded
    unless user&.reload&.can_add_more_kanji?
      errors.add(:user_kanji_limit, "exceeded")
    end
  end

  def notify_socket_subscribers(async: true)
    unless skip_turbostream_callbacks
      notify_outdated_next_kanji_pages(async: async)
    end
  end
end
