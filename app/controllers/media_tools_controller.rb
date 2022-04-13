class MediaToolsController < ApplicationController
  before_action :secure_behind_subscription

  MAX_TEXT_LENGTH = 135.freeze
  AUDIO_URL_SEPARATOR = "polly_audio_url::"
  AUDIO_FILENAME_SEPARATOR = "last_polly_filename::"

  def audio
    # remember to run `rails dev:cache` to test in local dev 💡
    last_audio_file = Rails.cache.read(user_converted_audio_key)

    if last_audio_file
      @audio_url, @filename = last_audio_file
        .split(AUDIO_FILENAME_SEPARATOR)
        .flat_map { |part| part.split(AUDIO_URL_SEPARATOR) }
        .reject(&:empty?)
        .map { |part| Base64.decode64(part) }
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
    write_succeeded = Rails.cache.write(
      user_converted_audio_key,
      "#{AUDIO_URL_SEPARATOR}#{Base64.encode64(audio_url).strip}#{AUDIO_FILENAME_SEPARATOR}#{Base64.encode64(filename).strip}",
      expires_in: 1.hour
    )
    raise "Failed cache write" unless write_succeeded

    conversions_used = @current_user.audio_conversions_used_this_month
    @current_user.update!(audio_conversions_used_this_month: conversions_used + 1)

    redirect_params = {}
    redirect_params[:use_neural_voice] = true if params[:use_neural_voice] == "true"
    redirect_to audio_media_tools_path(redirect_params)
  end

  private

  def user_converted_audio_key
    "#{@current_user.hashid}/last_converted_audio_file"
  end
end
