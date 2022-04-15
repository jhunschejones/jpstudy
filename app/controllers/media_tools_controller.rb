class MediaToolsController < ApplicationController
  before_action :secure_behind_subscription

  MAX_TEXT_LENGTH = 135.freeze
  AUDIO_URL_SEPARATOR = "polly_audio_url::"
  AUDIO_FILENAME_SEPARATOR = "last_polly_filename::"

  def audio
    # remember to run `rails dev:cache` to test in local dev 💡
    last_audio_file = Rails.cache.read(converted_audio_cache_key)

    if last_audio_file
      @audio_url, @filename = last_audio_file
        .split(AUDIO_FILENAME_SEPARATOR)
        .flat_map { |part| part.split(AUDIO_URL_SEPARATOR) }
        .reject(&:empty?)
        .map { |part| decode_cached_value(part) }
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
      japanese: params[:japanese].strip,
      english: params[:english].presence&.strip,
      user: @current_user,
      neural_voice: params[:use_neural_voice] == "true"
    ).convert_japanese_to_audio

    # remember to run `rails dev:cache` to test in local dev 💡
    cache_value = "#{AUDIO_URL_SEPARATOR}#{encoded_cache_value_for(audio_url)}#{AUDIO_FILENAME_SEPARATOR}#{encoded_cache_value_for(filename)}"
    write_succeeded = Rails.cache.write(converted_audio_cache_key, cache_value, expires_in: 1.hour)
    unless write_succeeded
      Rails.logger.warn("Failed cache value encodings: cache_value #{cache_value.encoding}, audio_url #{audio_url.encoding}, filename #{filename.encoding}")
      Rails.logger.warn("Failed cache value: #{cache_value}")
      Rails.logger.warn("Raw audio_url: #{audio_url}")
      Rails.logger.warn("Raw filename: #{filename}")
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

  def encoded_cache_value_for(string)
    # strict_encode64 does not add newlines like encode64 💡
    # Base64.strict_encode64(string.force_encoding(Encoding::UTF_8))
    string.force_encoding(Encoding::UTF_8)
  end

  def decode_cached_value(string)
    # Base64.decode64(string).force_encoding(Encoding::UTF_8)
    string.force_encoding(Encoding::UTF_8)
  end
end
