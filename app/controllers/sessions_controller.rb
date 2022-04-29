class SessionsController < ApplicationController
  MAX_LOGIN_ATTEMPTS = 10.freeze
  ALLOWED_DESTINATIONS = {
    "R01" => :words,
    "R02" => :kanji,
    "R03" => :word_search,
    "R04" => :user_stats,
    "R05" => :io,
    "R06" => :user_profile,
    "R07" => :memos
  }.freeze

  skip_before_action :authenticate_user
  before_action :prevent_brute_force, only: [:create]

  def new
    # Users who are logged in don't need to log in again
    if session[:session_token]
      return redirect_to(session.delete(:return_to)) if session[:return_to]
      user = User.find_by(session_token: session[:session_token])
      # prevent infinate redirects for expired session tokens
      if user.nil?
        reset_session
        clear_username_cookie
        return redirect_to(login_path)
      end
      return redirect_to words_path(user)
    end

    # Provide a controlled list of hard-coded messages to use with redirects
    case params[:message_id]
    when "S01"
      flash.now[:success] = "🙏 Thank you for subscribing! Please follow the link in your email to finalize your subscription."
    when "S02"
      flash.now[:success] = "Last step! Sign in to finish connecting your account to your shiny new subscription. ✨"
    when "E01"
      flash.now[:success] = "Email successfully verified! Please log in to use your account."
    end
  end

  def create
    user = User.find_by(email: params[:email])
    unless user.try(:authenticate, params[:password])
      return redirect_to login_url, alert: "Invalid email/password combination"
    end

    user.session_token ||= SecureRandom.base58(32)
    # Set the square_customer_id if this login is after a confirm_subscription_email
    user.square_customer_id = square_customer_id if params[:ref_id].present?
    user.save!

    session[:session_token] = user.session_token
    cookies.signed[:username] = {
      value: user.username,
      secure: Rails.env.production?,
      same_site: :strict,
      domain: Rails.env.production? ? "jpstudy.app" : "localhost"
    }
    flash.discard
    reset_login_attempts

    destination = ALLOWED_DESTINATIONS[params[:destination]]
    case destination
    when :words
      redirect_to words_path(user)
    when :kanji
      redirect_to next_kanji_path(user)
    when :word_search
      redirect_to search_words_path(user)
    when :user_stats
      redirect_to stats_user_path(user)
    when :io
      redirect_to in_out_user_path(user)
    when :user_profile
      redirect_to user
    when :memos
      redirect_to memos_path(user)
    else
      redirect_to session.delete(:return_to) || words_path(user.username)
    end
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    redirect_to login_url, alert: "Invalid token. If you are trying to confirm your subscription, please try following the link from your email."
  end

  def destroy
    reset_session
    clear_username_cookie
    redirect_to login_url, notice: "Succesfully logged out. またね！"
  end

  private

  def square_customer_id
    return nil unless params[:ref_id].present?
    ActiveSupport::MessageEncryptor
      .new(ENV["MESSAGE_ENCRYPTION_KEY"])
      .decrypt_and_verify(Base64.decode64(params[:ref_id]))
  end

  def prevent_brute_force
    increment_login_attempts
    if login_attempts >= MAX_LOGIN_ATTEMPTS
      redirect_to login_url, alert: "Maximum login attempts exceeded. Please try again in 15 minutes."
    end
  end

  def login_attempts_cache_key
    @login_attempts_cache_key ||= "#{params[:email]}/login_attempts"
  end

  def login_attempts
    @login_attempts ||= Rails.cache.read(login_attempts_cache_key).to_i
  end

  def increment_login_attempts
    @login_attempts = login_attempts + 1
    Rails.cache.write(login_attempts_cache_key, login_attempts, expires_in: 15.minutes)
    Rails.logger.info("#{login_attempts} login #{"attempt".pluralize(login_attempts)} for '#{params[:email]}'")
    NewRelic::Agent.add_custom_attributes({ login_attempts: login_attempts })
    login_attempts
  end

  def reset_login_attempts
    Rails.cache.delete(login_attempts_cache_key)
  end
end
