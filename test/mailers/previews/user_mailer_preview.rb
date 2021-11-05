# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  def welcome_email
    UserMailer
      .with(user: User.first, token: VerificationToken.generate)
      .welcome_email
  end

  # http://localhost:3000/rails/mailers/user_mailer/password_reset_email
  def password_reset_email
    UserMailer
      .with(user: User.first, token: ResetToken.generate)
      .password_reset_email
  end

  # http://localhost:3000/rails/mailers/user_mailer/confirm_subscription_email.html
  def confirm_subscription_email
    UserMailer
      .with(square_customer_id: "4E8DHP7FKGVPZCTVECVKTXEGM8", email: ENV["DEV_USER_EMAIL"])
      .confirm_subscription_email
  end
end
