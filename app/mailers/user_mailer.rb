class UserMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @token = params[:token]
    mail(to: @user.unverified_email || @user.email, subject: "Welcome to jpstudy")
  end

  def password_reset_email
    @user = params[:user]
    @token = params[:token]
    mail(to: @user.email, subject: "Password reset request")
  end

  def confirm_subscription_email
    @url = "https://www.jpstudy.herokuapp.com/login?ref_id=#{encrypt(params[:square_customer_id])}"
    mail(to: params[:email], subject: "Connect your jpstudy account")
  end

  private

  def encrypt(square_customer_id)
    encrypted_id = ActiveSupport::MessageEncryptor
      .new(ENV["MESSAGE_ENCRYPTION_KEY"])
      .encrypt_and_sign(square_customer_id)
    Base64.encode64(encrypted_id)
  end
end
