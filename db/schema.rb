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

ActiveRecord::Schema[7.0].define(version: 2022_05_18_222350) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "kanji", force: :cascade do |t|
    t.string "character", null: false
    t.string "status"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "added_to_list_at"
    t.index ["user_id", "character"], name: "index_kanji_on_user_id_and_character", unique: true
    t.index ["user_id"], name: "index_kanji_on_user_id"
  end

  create_table "memos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_memos_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "username"
    t.string "email"
    t.string "password_digest"
    t.string "role", default: "user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "square_customer_id"
    t.boolean "verified", default: false
    t.datetime "verified_at"
    t.datetime "verification_sent_at"
    t.string "verification_digest"
    t.string "unverified_email"
    t.datetime "reset_sent_at"
    t.string "reset_digest"
    t.datetime "trial_starts_at"
    t.datetime "trial_ends_at"
    t.bigint "word_limit"
    t.bigint "words_count"
    t.bigint "next_word_goal"
    t.bigint "daily_word_target"
    t.bigint "kanji_count"
    t.bigint "kanji_limit"
    t.bigint "next_kanji_goal"
    t.bigint "daily_kanji_target"
    t.string "session_token"
    t.bigint "audio_conversions_used_this_month", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["session_token"], name: "index_users_on_session_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "words", force: :cascade do |t|
    t.citext "japanese", null: false
    t.citext "english", null: false
    t.text "source_name"
    t.text "source_reference"
    t.boolean "checked", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.text "note"
    t.datetime "added_to_list_at"
    t.datetime "checked_at"
    t.boolean "starred", default: false
    t.index ["user_id", "japanese", "english"], name: "index_words_on_user_id_and_japanese_and_english", unique: true
    t.index ["user_id"], name: "index_words_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "kanji", "users"
  add_foreign_key "memos", "users"
  add_foreign_key "words", "users"
end
