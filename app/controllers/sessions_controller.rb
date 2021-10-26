class SessionsController < ApplicationController
  skip_before_action :authenticate_user

  def new
    if session[:user_id]
      redirect_to session.delete(:return_to) || root_path
    else
      render :new
    end
  end

  def create
    user = User.find_by(email: params[:email])
    if user.try(:authenticate, params[:password])
      session[:user_id] = user.id
      flash.discard
      redirect_to session.delete(:return_to) || root_path
    else
      redirect_to login_url, alert: "Invalid email/password combination"
    end
  end

  def destroy
    reset_session
    redirect_to login_url, notice: "Succesfully logged out"
  end
end
