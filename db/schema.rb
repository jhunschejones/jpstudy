# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_12_18_003925) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "plpgsql"

  create_table "kanji", force: :cascade do |t|
    t.string "character", null: false
    t.string "status"
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id", "character"], name: "index_kanji_on_user_id_and_character", unique: true
    t.index ["user_id"], name: "index_kanji_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "username"
    t.string "email"
    t.string "password_digest"
    t.string "role", default: "user"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "square_customer_id"
    t.boolean "verified", default: false
    t.datetime "verified_at", precision: 6
    t.datetime "verification_sent_at", precision: 6
    t.string "verification_digest"
    t.string "unverified_email"
    t.datetime "reset_sent_at", precision: 6
    t.string "reset_digest"
    t.datetime "trial_starts_at", precision: 6
    t.datetime "trial_ends_at", precision: 6
    t.bigint "word_limit"
    t.bigint "words_count"
    t.bigint "next_word_goal"
    t.bigint "daily_word_target"
    t.bigint "kanji_count"
    t.bigint "kanji_limit"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "words", force: :cascade do |t|
    t.citext "japanese", null: false
    t.citext "english", null: false
    t.text "source_name"
    t.text "source_reference"
    t.boolean "cards_created", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.text "note"
    t.datetime "added_to_list_at", precision: 6
    t.datetime "cards_created_at", precision: 6
    t.index ["user_id", "japanese", "english"], name: "index_words_on_user_id_and_japanese_and_english", unique: true
    t.index ["user_id"], name: "index_words_on_user_id"
  end

  add_foreign_key "kanji", "users"
  add_foreign_key "words", "users"
end
