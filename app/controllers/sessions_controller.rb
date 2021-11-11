class SessionsController < ApplicationController
  skip_before_action :authenticate_user

  def new
    if session[:user_id]
      redirect_to session.delete(:return_to) || words_path
    else
      render :new
    end
  end

  def create
    user = User.find_by(email: params[:email])
    if user.try(:authenticate, params[:password])
      session[:user_id] = user.id
      flash.discard
      # Set the square_customer_id if this login is after a confirm_subscription_email
      if params[:ref_id].present?
        user.update!(square_customer_id: square_customer_id, password: params[:password])
      end
      redirect_to session.delete(:return_to) || root_path
    else
      redirect_to login_url, alert: "Invalid email/password combination"
    end
  end

  def destroy
    reset_session
    redirect_to login_url, notice: "Succesfully logged out"
  end

  private

  def square_customer_id
    return nil unless params[:ref_id].present?
    ActiveSupport::MessageEncryptor
      .new(ENV["MESSAGE_ENCRYPTION_KEY"])
      .decrypt_and_verify(Base64.decode64(params[:ref_id]))
  end
end
