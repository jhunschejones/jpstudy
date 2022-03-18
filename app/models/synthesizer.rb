class Synthesizer
  class InvalidJapanese < StandardError; end

  POLLY = Aws::Polly::Client.new
  S3 = Aws::S3::Resource.new
  FEMALE_VOICE_ID = "Mizuki".freeze
  MALE_VOICE_ID = "Takumi".freeze
  VOICE_SPEED = "slow".freeze # x-slow, slow, medium, fast, or x-fast
  AWS_BUCKET = "jpstudy".freeze

  NON_WORD_NON_SPACE_CHARACTERS = /[^\w\s一-龯ぁ-んァ-ン０-９Ａ-ｚ]/

  def initialize(japanese:, english: nil, user:, polly: POLLY, s3: S3)
    @japanese = japanese
    @english = english
    @user = user
    @polly = polly
    @s3 = s3
  end

  # returns a 2-element array of audio_url and filename
  def convert_japanese_to_audio
    polly_audio_stream = @polly
      .synthesize_speech(
        {
          output_format: "mp3",
          text: "<speak><prosody rate='#{VOICE_SPEED}'>#{@japanese}</prosody></speak>",
          voice_id: FEMALE_VOICE_ID,
          text_type: "ssml"
        }
      ).audio_stream

    s3_file_object = @s3
      .bucket(AWS_BUCKET)
      .object("polly/#{@user.hashid}/#{safe_filename_with_extension}")
    s3_file_object.put(body: polly_audio_stream)

    [s3_file_object.presigned_url(:get, expires_in: 3600), safe_filename_with_extension]
  end

  private

  def safe_filename
    @safe_filename ||= begin
      return default_filename if @english.nil? || @english.empty?
      safe_filename = @english.gsub(NON_WORD_NON_SPACE_CHARACTERS, "")
      safe_filename.empty? ? default_filename : safe_filename
    end
  end

  def safe_filename_with_extension
    "#{safe_filename}.mp3"
  end

  def default_filename
    # Use a millisecond timestamp as the default filename if the user did not
    # provide a valid filename.
    (Time.now.to_f * 1000).to_i.to_s
  end
end
