class MediaToolsController < ApplicationController
  before_action :secure_behind_subscription

  MAX_TEXT_LENGTH = 135.freeze
  AUDIO_URL_SEPARATOR = "polly_audio_url::"
  AUDIO_FILENAME_SEPARATOR = "last_polly_filename::"

  def audio
    # remember to run `rails dev:cache` to test in local dev 💡
    last_audio_file = Rails.cache.read(converted_audio_cache_key)

    if last_audio_file
      @filename, @audio_url = Synthesizer
        .new(user: @current_user)
        .url_for_japanese_audio(s3_key: last_audio_file)
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

    s3_file_key = Synthesizer
      .new(user: @current_user)
      .convert_japanese_to_audio(
        japanese: params[:japanese].strip,
        english: params[:english].presence&.strip,
        neural_voice: params[:use_neural_voice] == "true"
      )

    # remember to run `rails dev:cache` to test in local dev 💡
    max_tries = ENV.fetch("REDIS_WRITE_TRIES", "1").to_i
    tries = 0
    last_write_succeeded = false
    until last_write_succeeded || tries >= max_tries
      last_write_succeeded = Rails.cache.write(converted_audio_cache_key, s3_file_key, expires_in: 1.hour)
      tries += 1
    end
    unless last_write_succeeded
      Rails.logger.warn("Failed cache key: #{converted_audio_cache_key}")
      Rails.logger.warn("Failed cache value: #{s3_file_key}")
      Rails.logger.warn("Cache write tries: #{tries}")
      raise "JPSTUDY ERROR: FAILED CACHE WRITE"
    end

    conversions_used = @current_user.audio_conversions_used_this_month
    @current_user.update!(audio_conversions_used_this_month: conversions_used + 1)

    redirect_params = {}
    redirect_params[:use_neural_voice] = true if params[:use_neural_voice] == "true"
    redirect_to audio_media_tools_path(redirect_params)
  end

  private

  def converted_audio_cache_key
    "#{@current_user.hashid}/last_converted_audio_file"
  end
end
