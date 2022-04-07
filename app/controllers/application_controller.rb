class ApplicationController < ActionController::Base
  add_flash_types :success
  before_action :authenticate_user

  private

  def secure_behind_subscription
    authenticate_user
    return true if @current_user.role == User::ADMIN_ROLE
    return true if @current_user.trial_active?
    return true if subscription_already_verified?

    if @current_user.active_subscription.present?
      session[:reverify_subscription_at] = @current_user.active_subscription.next_charge_date.utc
      return true
    end

    flash[:notice] = "Your trial has expired. Please subscribe to access full site functionality."
    redirect_to @current_user
  end

  def authenticate_user
    set_current_user
    unless @current_user.present?
      session[:return_to] ||= request.url
      redirect_to login_url, notice: "ようこそ！ Please log in to access your account and full site functionality."
    end
  end

  def set_current_user
    @current_user ||= session[:session_token].presence && User.find_by(session_token: session[:session_token])
    if @current_user
      NewRelic::Agent.add_custom_attributes({ user: @current_user.username })
    else
      # prevent redirect loop on invalid session_token
      reset_session
      clear_username_cookie
    end
    @current_user
  end

  def subscription_already_verified?
    session[:reverify_subscription_at] && Time.parse(session[:reverify_subscription_at]).utc > Time.now.utc
  end

  def protect_user_scoped_resource
    authenticate_user
    head :not_found if params[:username] && @current_user.username != params[:username]
    @resource_owner ||= begin
      if params[:username].blank?
        nil
      elsif params[:username] == @current_user&.username
        @current_user # save a query if we've already looked this user up safely earlier
      else
        User.find_by(username: params[:username])
      end
    end
  end

  def clear_username_cookie
    cookies.delete(:username, domain: Rails.env.production? ? "jpstudy.app" : "localhost")
  end
end
