class UserMailer < ApplicationMailer
  def confirm_subscription_email
    @url = "https://www.jpstudy.herokuapp.com/login?ref_id=#{encrypt(params[:square_customer_id])}"
    mail(to: params[:email], subject: "Connect your JP Study account")
  end

  private

  def encrypt(square_customer_id)
    encrypted_id = ActiveSupport::MessageEncryptor
      .new(ENV["MESSAGE_ENCRYPTION_KEY"])
      .encrypt_and_sign(square_customer_id)
    Base64.encode64(encrypted_id)
  end
end
