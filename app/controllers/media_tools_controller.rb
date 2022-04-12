class MediaToolsController < ApplicationController
  before_action :secure_behind_subscription

  MAX_TEXT_LENGTH = 135.freeze

  def audio
    if params[:show_latest_conversion]
      # remember to run `rails dev:cache` to test in local dev 💡
      @audio_url = Rails.cache.read(user_audio_url_cache_key)
      @filename = Rails.cache.read(user_audio_filename_cache_key)
    end

    unless @current_user.can_do_more_audio_conversions?
      flash.now[:alert] = "Users are limited to #{User::MAX_MONTHLY_AUDIO_CONVERSIONS} conversions per month. Please contact support if you need additional audio conversions."
    end
  end

  def japanese_to_audio
    if params[:japanese].blank?
      return redirect_to audio_media_tools_path, notice: "Please provide some Japanese text to convert"
    end
    if params[:japanese].size > MAX_TEXT_LENGTH || (params[:english] && params[:english].size > MAX_TEXT_LENGTH)
      flash[:notice] = "Input text must be no longer than #{MAX_TEXT_LENGTH} characters"
      return redirect_to audio_media_tools_path
    end
    unless @current_user.can_do_more_audio_conversions?
      flash[:alert] = "Users are limited to #{User::MAX_MONTHLY_AUDIO_CONVERSIONS} conversions per month. Please contact support if you need additional audio conversions."
      return redirect_to audio_media_tools_path
    end

    audio_url, filename = Synthesizer.new(
      japanese: params[:japanese],
      english: params[:english].presence,
      user: @current_user,
      neural_voice: params[:use_neural_voice] == "true"
    ).convert_japanese_to_audio

    Rails.cache.write(user_audio_url_cache_key, audio_url, expires_in: 1.hour)
    Rails.cache.write(user_audio_filename_cache_key, filename, expires_in: 1.hour)
    conversions_used = @current_user.audio_conversions_used_this_month
    @current_user.update!(audio_conversions_used_this_month: conversions_used + 1)

    redirect_params = { show_latest_conversion: true }
    redirect_params[:use_neural_voice] = true if params[:use_neural_voice] == "true"
    redirect_to audio_media_tools_path(redirect_params)
  end

  private

  def user_audio_url_cache_key
    "#{@current_user.hashid}/last_polly_audio_url"
  end

  def user_audio_filename_cache_key
    "#{@current_user.hashid}/last_polly_filename"
  end
end
