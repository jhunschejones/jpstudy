class PasswordsController < ApplicationController
  skip_before_action :authenticate_user

  def forgot_form
  end

  def reset_form
  end

  def forgot
    return redirect_to login_url, alert: "Email not present" if params[:email].blank?

    user = User.find_by(email: params[:email])

    if user.present?
      reset_token = ResetToken.generate
      UserMailer
        .with(user: user, token: reset_token)
        .password_reset_email
        .deliver_later
      user.update(reset_sent_at: Time.now.utc, reset_digest: reset_token.digest)
    end
    # Do not tell the user if an account exists for a specified email
    redirect_to login_url, notice: "Please check your email for a password reset link"
  end

  def reset
    [:token, :user_id].each do |required_param|
      if params[required_param].blank?
        return redirect_to login_url, alert: "Missing #{required_param}. Please follow the link from your verification email."
      end
    end

    if params[:password].blank? || params[:password_confirmation].blank? || params[:email].blank?
      flash[:alert] = "Enter your email and confirm your new password"
      return redirect_to password_reset_path(token: params[:token])
    end

    if params[:password] != params[:password_confirmation]
      flash[:alert] = "Your new password and confirmation must match"
      return redirect_to password_reset_path(token: params[:token])
    end

    user = User.find_by(id: params[:user_id])

    unless user.present? && ResetToken.is_valid?(user: user, token: params[:token])
      flash[:alert] =  "Invalid or expired link. Please check your email or generate a new link."
      return redirect_to login_url
    end

    if user.reset_password(params[:password])
      redirect_to login_url, success: "Password successfully reset! Please log in with your new password."
    else
      redirect_to password_reset_path, alert: user.errors.full_messages
    end
  end
end
