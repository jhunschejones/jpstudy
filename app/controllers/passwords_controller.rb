class PasswordsController < ApplicationController
  skip_before_action :authenticate_user

  def new
  end

  def forgot
    return redirect_to login_url, alert: "Email not present" if params[:email].blank?

    user = User.find_by(email: params[:email])

    if user.present?
      token = Token.generate(expires_at: 4.hours.from_now.utc)
      UserMailer.password_reset_email(user, token).deliver_later
      user.update(reset_sent_at: Time.now.utc, reset_digest: token.digest)
    end
    # Do not tell the user if an account exists for a specified email
    redirect_to login_url, notice: "Please check your email for a password reset link"
  end

  def reset
    if params[:token].blank?
      flash[:alert] = "Missing reset token. Please follow the link from your reset email."
      return redirect_to login_url
    end

    if params[:password].blank? || params[:password_confirmation].blank? || params[:email].blank?
      flash[:alert] = "Enter your email and confirm your new password"
      return redirect_to password_reset_path(token: params[:token])
    end

    if params[:password] != params[:password_confirmation]
      flash[:alert] = "Your new password and confirmation must match"
      return redirect_to password_reset_path(token: params[:token])
    end

    token = Token.new(params[:token])
    user = User.find_by(reset_digest: token.digest)

    unless user.present? && token.valid_for?(user.reset_digest)
      flash[:alert] =  "Invalid or expired link. Please check your email or generate a new link."
      return redirect_to login_url
    end

    if user.reset_password(params[:password])
      redirect_to login_url, success: "Password successfully reset! Please log in with your new password."
    else
      return render render :new, alert: user.errors.full_messages
    end
  end
end
