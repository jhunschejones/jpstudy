class UsersController < ApplicationController
  before_action :set_user, except: [:new, :create]
  before_action :set_current_user, only: [:new] # tries to look up user from session and silently continues if one cannot be found
  before_action :protect_user, except: [:new, :create, :stats]
  before_action ->{ protect_user_scoped_read_actions_for(:stats) }, only: [:stats]
  skip_before_action :authenticate_user, only: [:new, :create]
  before_action :secure_behind_subscription, only: [:in_out]

  def show
  end

  def new
    return redirect_to @current_user, notice: "You are already logged in to your account!" if @current_user
    @user = User.new
  end

  def edit
  end

  def create
    if ENV["MAX_USERS"] && User.count >= ENV["MAX_USERS"].to_i
      @user = User.new(user_params.merge({
        word_limit: User::DEFAULT_WORD_LIMIT,
        kanji_limit: User::DEFAULT_KANJI_LIMIT
      }))
      if @user.save
        flash[:alert] = "We are not accepting additional users for the alpha release at this time. We will contact you as soon as a spot opens."
        return redirect_to login_url
      else
        flash[:alert] = "Unable to create user: #{@user.errors.full_messages.map(&:downcase).join(", ")}"
        return redirect_to new_user_path
      end
    end

    verification_token = VerificationToken.generate
    @user = User.new(
      user_params.merge({
        verification_digest: verification_token.digest,
        verification_sent_at: Time.now.utc,
        trial_starts_at: Time.now.utc,
        trial_ends_at: Time.now.utc + 30.days,
        word_limit: User::DEFAULT_WORD_LIMIT,
        kanji_limit: User::DEFAULT_KANJI_LIMIT
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
    if user_target_params.present?
      @user.update(user_target_params)
      return redirect_to stats_user_path(@user), success: "Your study targets have been updated."
    end

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
    clear_username_cookie
    redirect_to login_url, notice: "Your account has been deleted."
  end

  def stats
    @checked_words_count = @current_user.words.where(checked: true).size
    @words_not_checked_count = @current_user.words.not_checked.size
    @words_checked_today_count = @current_user.words.where(checked_at: Date.today.all_day).size
    # Instance variable is set to nil if next_word_goal and daily_word_target are not configured yet
    @days_to_word_target =
      if @current_user.next_word_goal && @current_user.daily_word_target && @current_user.next_word_goal > @checked_words_count
        ((@current_user.next_word_goal - @checked_words_count).to_f / @current_user.daily_word_target.to_f).ceil
      end

    @kanji_added_count = @current_user.kanji.added.count
    @kanji_skipped_count = @current_user.kanji.skipped.count
    @kanji_to_add_count = Kanji.all_new_characters_for(user: @current_user).size
    @kanji_added_today = @current_user.kanji.added.where(added_to_list_at: Date.today.all_day).size
    # Instance variable is set to nil if next_kanji_goal and daily_kanji_target are not configured yet
    @days_to_kanji_target =
      if @current_user.next_kanji_goal && @current_user.daily_kanji_target && @current_user.next_kanji_goal > @kanji_added_count
        ((@current_user.next_kanji_goal - @kanji_added_count).to_f / @current_user.daily_kanji_target.to_f).ceil
      end

    if @current_user.has_reached_or_exceeded_daily_word_target? && @current_user.has_reached_or_exceeded_daily_kanji_target?
      flash.now[:success] = "🎉 You reached your daily word and kanji targets!"
    elsif @current_user.has_reached_or_exceeded_daily_word_target?
      flash.now[:success] = "🎉 You reached your daily word target!"
    elsif @current_user.has_reached_or_exceeded_daily_kanji_target?
      flash.now[:success] = "🎉 You reached your daily kanji target!"
    end
  end

  def edit_targets
  end

  def before_you_go
  end

  def in_out
  end

  private

  def set_user
    @user = User.find_by(username: params[:username])
  end

  def user_params
    params.require(:user).permit(:name, :username, :email, :password, :password_confirmation)
  end

  def user_target_params
    params.require(:user).permit(:next_word_goal, :daily_word_target, :next_kanji_goal, :daily_kanji_target)
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
