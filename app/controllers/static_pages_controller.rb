class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user
  before_action :set_current_user # Set the user is logged in, if not silently pass the request through

  def about
  end
end
