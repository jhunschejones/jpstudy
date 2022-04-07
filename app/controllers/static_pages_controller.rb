class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user
  before_action :set_current_user # tries to look up user from session and silently continues if one cannot be found

  def about
  end

  def word_list_instructions
  end

  def next_kanji_instructions
  end

  def content_limits
  end

  def keyboard_shortcuts
  end
end
