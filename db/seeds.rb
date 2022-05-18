dev_user = User.find_by(email: ENV.fetch("DEV_USER_EMAIL")) || begin
  User.create!(
    name: ENV.fetch("DEV_USER_NAME"),
    email: ENV.fetch("DEV_USER_EMAIL"),
    username: ENV.fetch("DEV_USER_USERNAME"),
    password: ENV.fetch("DEV_USER_PASSWORD"),
    password_confirmation: ENV.fetch("DEV_USER_PASSWORD"),
    verified: true,
    word_limit: User::DEFAULT_WORD_LIMIT,
    kanji_limit: User::DEFAULT_KANJI_LIMIT,
    trial_starts_at: Time.now,
    trial_ends_at: Time.now + 14.days
  )
end
dev_user.update!(trial_ends_at: Time.now + 14.days)

dev_user_2 = User.find_by(email: ENV.fetch("DEV_USER_2_EMAIL")) || begin
  User.create!(
    name: ENV.fetch("DEV_USER_2_NAME"),
    email: ENV.fetch("DEV_USER_2_EMAIL"),
    username: ENV.fetch("DEV_USER_2_USERNAME"),
    password: ENV.fetch("DEV_USER_2_PASSWORD"),
    password_confirmation: ENV.fetch("DEV_USER_2_PASSWORD"),
    verified: true,
    word_limit: User::DEFAULT_WORD_LIMIT,
    kanji_limit: User::DEFAULT_KANJI_LIMIT,
    trial_starts_at: Time.now,
    trial_ends_at: Time.now + 14.days
  )
end
dev_user_2.update!(trial_ends_at: Time.now + 14.days)

Word.create_with(
  source_name: "Minna No Nihongo",
  source_reference: "17",
  checked_off: true,
  added_to_list_at: Time.now.utc - 5.minutes
).find_or_create_by!(
  japanese: "二日酔い",
  english: "hangover",
  user: dev_user
)

Word.create_with(
  source_name: "Nihongo So-matome",
  source_reference: "4-1",
  added_to_list_at: Time.now.utc - 4.minutes
).find_or_create_by!(
  japanese: "予定",
  english: "plans, schedule",
  user: dev_user
)

Word.create_with(
  source_name: "Minna No Nihongo",
  source_reference: "16",
  added_to_list_at: Time.now.utc - 3.minutes
).find_or_create_by!(
  japanese: "ボタン",
  english: "button",
  user: dev_user
)

Word.create_with(
  source_name: "Duolingo",
  added_to_list_at: Time.now.utc - 6.minutes
).find_or_create_by!(
  japanese: "ハト",
  english: "pigeon",
  user: dev_user_2
)
