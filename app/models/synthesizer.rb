class Synthesizer
  POLLY = Aws::Polly::Client.new
  S3 = Aws::S3::Resource.new
  FEMALE_VOICE_ID = "Mizuki".freeze
  MALE_VOICE_ID = "Takumi".freeze
  VOICE_SPEED = "slow".freeze # x-slow, slow, medium, fast, or x-fast
  AWS_BUCKET = "jpstudy".freeze
  CONTENT_DISPOSITION_REGEX = /.+(response-content-disposition=inline%3B%20filename%3D.+)&response-content-type/

  NON_WORD_NON_SPACE_CHARACTERS = /[^\w\s一-龯ぁ-んァ-ン０-９Ａ-ｚ]/

  def initialize(user:, polly: POLLY, s3: S3)
    @user = user
    @polly = polly
    @s3 = s3
  end

  def convert_japanese_to_audio(japanese:, english: nil, neural_voice: false)
    polly_audio_stream = @polly
      .synthesize_speech(
        {
          output_format: "mp3",
          text: "<speak><prosody rate='#{VOICE_SPEED}'>#{japanese}</prosody></speak>",
          voice_id: neural_voice ? MALE_VOICE_ID : FEMALE_VOICE_ID, # neural Japanese is only available for Takumi
          text_type: "ssml",
          engine: neural_voice ? "neural" : "standard"
        }
      ).audio_stream

    s3_file_key = "polly/#{@user.hashid}/#{safe_filename_with_extension(english)}"
    @s3.bucket(AWS_BUCKET).put_object(
        body: polly_audio_stream,
        key: s3_file_key,
        content_type: "audio/mpeg",
        tagging: "media-source=polly"
      )

    s3_file_key
  end

  # returns a tuple of filename, audio_url
  def url_for_japanese_audio(s3_key:)
    filename = s3_key.gsub("polly/#{@user.hashid}/", "")
    audio_url = @s3
      .bucket(AWS_BUCKET)
      .object(s3_key)
      .presigned_url(
        :get,
        expires_in: 3600,
        response_content_disposition: "inline; filename=#{filename}",
        response_content_type: "audio/mpeg"
      )

    # Doing a little hacky dance here to get the URL to end in `.mp3`,
    # thereby allowing Anki's auto-download feature to work.
    if audio_url.match?(CONTENT_DISPOSITION_REGEX)
      content_disposition = audio_url.match(CONTENT_DISPOSITION_REGEX)[1]
      audio_url_minus_content_disposition = audio_url.gsub(content_disposition, "").gsub("?&", "?")
      audio_url = "#{audio_url_minus_content_disposition}&#{content_disposition}"
    end

    [filename, audio_url]
  end

  private

  def safe_filename(filename)
    return default_filename if filename.nil? || filename.empty?
    safe_filename = filename.gsub(NON_WORD_NON_SPACE_CHARACTERS, "")
    safe_filename.empty? ? default_filename : safe_filename
  end

  def safe_filename_with_extension(filename)
    "#{safe_filename(filename)}.mp3"
  end

  def default_filename
    # Use a millisecond timestamp as the default filename if the user did not
    # provide a valid filename.
    (Time.now.to_f * 1000).to_i.to_s
  end
end
