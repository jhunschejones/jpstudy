class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :stats]
  before_action :protect_user, except: [:new, :create]
  skip_before_action :authenticate_user, only: [:new, :create]
  before_action :set_current_user, only: [:new] # tries to look up user from session and silently continues if one cannot be found

  def show
  end

  def new
    return redirect_to @current_user, notice: "You are already logged in to your account!" if @current_user
    @user = User.new
  end

  def edit
  end

  def create
    verification_token = VerificationToken.generate
    @user = User.new(
      user_params.merge({
        verification_digest: verification_token.digest,
        verification_sent_at: Time.now.utc,
        trial_starts_at: Time.now.utc,
        trial_ends_at: Time.now.utc + 30.days,
        word_limit: User::DEFAULT_WORD_LIMIT,
      })
    )

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
      redirect_to @user, success: "Your user details have been updated."
    else
      flash[:alert] = "Unable to update user details: #{@user.errors.full_messages.map(&:downcase).join(", ")}"
      redirect_to edit_user_path(@user)
    end
  end

  def destroy
    @user.destroy
    reset_session
    redirect_to root_path, alert: "Your account has been deleted."
  end

  def stats
    @total_words_created_count = @current_user.words.size
    @words_with_cards_created_count = @current_user.words.where(cards_created: true).size
    @words_ready_for_cards_count = @current_user.words.cards_not_created.size
    @words_with_cards_created_today = @current_user.words.where(cards_created_at: Date.today.all_day).size
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
      # don't tell the user that they found another user's account
      head :not_found
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
