dev_user = User.find_by(email: ENV.fetch("DEV_USER_EMAIL")) || begin
  User.create!(
    name: ENV.fetch("DEV_USER_NAME"),
    email: ENV.fetch("DEV_USER_EMAIL"),
    username: ENV.fetch("DEV_USER_USERNAME"),
    password: ENV.fetch("DEV_USER_PASSWORD"),
    password_confirmation: ENV.fetch("DEV_USER_PASSWORD")
  )
end

Word.find_or_create_by!(
  japanese: "二日酔い",
  english: "hangover",
  source_name: "Minna No Nihongo",
  source_reference: "17",
  cards_created: true,
  user: dev_user
)
Word.find_or_create_by!(
  japanese: "予定",
  english: "plans, schedule",
  source_name: "Nihongo So-matome",
  source_reference: "4-1",
  user: dev_user
)
Word.find_or_create_by!(
  japanese: "ボタン",
  english: "button",
  source_name: "Minna No Nihongo",
  source_reference: "16",
  user: dev_user
)
