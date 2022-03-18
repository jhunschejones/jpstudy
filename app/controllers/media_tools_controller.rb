class MediaToolsController < ApplicationController
  before_action :secure_behind_subscription

  MAX_TEXT_LENGTH = 135.freeze
  MAX_MONTHLY_CONVERSIONS = 500.freeze

  def audio
    @audio_url = params[:audio_url].presence && CGI.unescape(params[:audio_url])
    @filename = params[:filename]
  end

  def japanese_to_audio
    unless params[:japanese].present?
      return redirect_to audio_media_tools_path, notice: "Please provide some Japanese text to convert"
    end
    if params[:japanese].size > MAX_TEXT_LENGTH || (params[:english] && params[:english].size > MAX_TEXT_LENGTH)
      return redirect_to audio_media_tools_path, notice: "Input text must be no longer than #{MAX_TEXT_LENGTH} characters"
    end
    if (conversions_used = @current_user.audio_conversions_used_this_month) >= MAX_MONTHLY_CONVERSIONS
      return redirect_to audio_media_tools_path, alert: "Users are limited to #{MAX_MONTHLY_CONVERSIONS} conversions per month. Please contact support if you need additional audio conversions."
    end

    audio_url, filename = Synthesizer.new(
      japanese: params[:japanese],
      english: params[:english].presence,
      user: @current_user
    ).convert_japanese_to_audio
    @current_user.update!(
      audio_conversions_used_this_month: conversions_used + 1
    )
    redirect_to audio_media_tools_path(
      audio_url: CGI.escape(audio_url),
      filename: filename
    )
  end
end
