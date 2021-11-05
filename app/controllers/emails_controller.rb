class EmailsController < ApplicationController
  skip_before_action :authenticate_user

  def verify
    if params[:token].blank?
      flash[:alert] = "Missing verification token. Please follow the link from your verification email."
      return redirect_to login_url
    end

    token = Token.new(params[:token])
    user = User.find_by(verification_digest: token.digest)

    unless user.present? && VerificationToken.valid?(user: user, token: token)
      return redirect_to login_url, alert: "Invalid link. Use 'forgot password' to generate a new link."
    end

    unless user.verify_email
      return render :new, alert: user.errors.full_messages
    end

    # If this is being used for an email change, update the new email
    if user.unverified_email
      user.update(
        email: user.unverified_email,
        unverified_email: nil
      )
    end

    redirect_to login_url, success: "Email successfully verified! Please log in to use your account."
  end
end
