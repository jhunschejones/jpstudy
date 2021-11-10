class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :protect_user, except: [:new, :create]
  skip_before_action :authenticate_user, only: [:new, :create]

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)
    verification_token = VerificationToken.generate
    @user.verification_digest = verification_token.digest
    @user.verification_sent_at = Time.now.utc
    @user.trial_starts_at = Time.now.utc
    @user.trial_ends_at = Time.now.utc + 30.days

    if @user.save
      UserMailer
        .with(user: @user, token: verification_token)
        .welcome_email
        .deliver_later
      flash[:success] = "User #{@user.username} was successfully created. Please follow the verification link in your email."
      redirect_to login_url
    else
      flash[:alert] = "Unable to create user: #{@user.errors.full_messages.map(&:downcase).join(", ")}"
      redirect_to new_user_path
    end
  end

  def update
    if changing_email?
      if email_is_not_unique?
        flash[:alert] = "Emails must be unique, please request a password reset if you cannot access your account"
        return redirect_to edit_user_path(@user)
      end

      # securely verify new email without locking users out of their accounts
      verification_token = VerificationToken.generate
      @user.unverified_email = user_params[:email]
      @user.verification_digest = verification_token.digest
      @user.verification_sent_at = Time.now.utc

      UserMailer
        .with(user: @user, token: verification_token)
        .welcome_email
        .deliver_later
      flash[:notice] = "Please follow the verification link sent to your new email to confirm the change"
    end

    if @user.update(user_params.except(:email))
      redirect_to @user, success: "User was successfully updated."
    else
      flash[:alert] = "Unable to update user: #{@user.errors.full_messages.map(&:downcase).join(", ")}"
      redirect_to edit_user_path(@user)
    end
  end

  def destroy
    @user.destroy
    reset_session
    redirect_to root_url, alert: "Your account has been deleted."
  end

  private

  def set_user
    @user = User.find_by(username: params[:username])
  end

  def user_params
    params.require(:user).permit(:name, :username, :email, :password, :password_confirmation)
  end

  def protect_user
    unless @user == @current_user
      redirect_to @current_user, alert: "You cannot access data that belongs to other users"
    end
  end

  def changing_email?
    user_params[:email].present? && user_params[:email] != @user.email
  end

  def email_is_not_unique?
    User
      .where(email: user_params[:email])
      .or(User.where(unverified_email: user_params[:email]))
      .exists?
  end
end
