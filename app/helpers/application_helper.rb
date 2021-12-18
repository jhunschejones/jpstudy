module ApplicationHelper
  def page_subtitle_helper
    if controller_name == "users"
      return " | profile" if action_name == "show"
      return " | update profile" if action_name == "edit"
      return " | stats" if action_name == "stats"
      return " | signup" if action_name == "new"
    end

    if controller_name == "static_pages"
      return " | #{action_name.titleize.downcase}"
    end

    if controller_name == "words"
      return " | word list" if action_name == "index"
      return " | word details" if action_name == "show"
      return " | edit word" if action_name == "edit"
      return " | new word" if action_name == "new"
      return " | search" if action_name == "search"
      return " | in / out" if action_name == "in_out"
      return " | import words" if action_name == "import"
      return " | export words" if action_name == "export"
    end

    if controller_name == "kanji"
      return " | next kanji" if action_name == "next"
      return " | import kanji" if action_name == "import"
      return " | export kanji" if action_name == "export"
    end

    if controller_name == "sessions"
      return " | login" if action_name == "new"
    end

    if controller_name == "emails"
      # no views here
    end

    if controller_name == "passwords"
      return " | password reset" if action_name == "reset_form"
      return " | forgot password" if action_name == "forgot_form"
    end
  end
end
