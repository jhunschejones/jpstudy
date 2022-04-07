class EmailsController < ApplicationController
  skip_before_action :authenticate_user
  before_action :set_current_user # tries to look up user from session and silently continues if one cannot be found

  def verify
    return redirect_to @current_user, notice: "You are already logged in to your account!" if @current_user

    [:token, :username].each do |required_param|
      if params[required_param].blank?
        flash[:alert] = "Missing #{required_param}. Please follow the link from your verification email."
        return redirect_to login_url
      end
    end

    user = User.find_by(username: params[:username])

    unless user.present? && VerificationToken.is_valid?(user: user, token: params[:token])
      flash[:alert] = "Invalid link. Use 'forgot password' to generate a new link."
      return redirect_to login_url
    end

    unless user.verify_email
      flash[:alert] = "Unable to verify email: #{user.errors.full_messages.map(&:downcase).join(", ")}"
      return redirect_to login_url
    end

    # If this is being used for an email change, update the new email
    if user.unverified_email
      user.email = user.unverified_email
      user.unverified_email = nil
    end

    user.session_token = nil # force logout
    user.save!
    reset_session
    clear_username_cookie
    redirect_to login_url(message_id: "E01")
  end
end
