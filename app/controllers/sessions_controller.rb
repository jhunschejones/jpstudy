class SessionsController < ApplicationController
  skip_before_action :authenticate_user

  def new
    # Users who are logged in don't need to log in again
    if session[:user_id]
      return redirect_to session.delete(:return_to) || words_path
    end

    # Provide a controlled list of hard-coded messages to use with redirects
    case params[:message_id]
    when "S01"
      flash.now[:success] = "🙏 Thank you for subscribing! Please follow the link in your email to finalize your subscription."
    end
  end

  def create
    user = User.find_by(email: params[:email])
    if user.try(:authenticate, params[:password])
      session[:user_id] = user.id
      flash.discard
      # Set the square_customer_id if this login is after a confirm_subscription_email
      user.update!(square_customer_id: square_customer_id) if params[:ref_id].present?
      redirect_to session.delete(:return_to) || words_path
    else
      redirect_to login_url, alert: "Invalid email/password combination"
    end
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    redirect_to login_url, alert: "Invalid token. If you are trying to confirm your subscription, please try following the link from your email."
  end

  def destroy
    reset_session
    redirect_to login_url, notice: "Succesfully logged out. またね！"
  end

  private

  def square_customer_id
    return nil unless params[:ref_id].present?
    ActiveSupport::MessageEncryptor
      .new(ENV["MESSAGE_ENCRYPTION_KEY"])
      .decrypt_and_verify(Base64.decode64(params[:ref_id]))
  end
end
