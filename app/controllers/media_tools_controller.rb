class MediaToolsController < ApplicationController
  before_action :secure_behind_subscription

  def audio
    @japanese_to_audio_file = "/public/audio/thanks.mp3"
    @filename = "thanks"
  end

  def japanese_to_audio
    @japanese_to_audio_file = "/public/audio/thanks.mp3"
    @filename = params[:filename]
    # Synthesizer.new(
    #   japanese: params[:japanese],
    #   filename: params[:filename].presence
    # ).convert_japanese_to_audio
    render :audio
  rescue InvalidJapanese
    redirect_to audio_path, alert: "'#{params[:japanese]}' appears to contain some non-Japanese characters"
  end
end
