class ApplicationController < ActionController::Base
  add_flash_types :success
  before_action :authenticate_user

  private

  def authenticate_user
    @current_user ||= session[:user_id].present? ? User.find_by(id: session[:user_id]) : nil
    unless @current_user.present?
      session[:return_to] ||= request.url
      redirect_to login_url, notice: "ようこそ！ Please log in to access your jpstudy account"
    end
  end
end
