# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  # http://localhost:3000/rails/mailers/user_mailer/confirm_subscription_email.html
  def confirm_subscription_email
    UserMailer
      .with(square_customer_id: "4E8DHP7FKGVPZCTVECVKTXEGM8", email: ENV["DEV_USER_EMAIL"])
      .confirm_subscription_email
  end
end
