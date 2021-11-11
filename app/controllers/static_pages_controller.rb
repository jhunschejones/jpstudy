class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user
  before_action :set_current_user # Set the user is logged in, if not silently pass the request through

  def about
  end

  def word_list_instructions
  end

  def word_limit_explanation
    @word_limit = User::DEFAULT_WORD_LIMIT
  end
end
