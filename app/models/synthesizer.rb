class Synthesizer
  class InvalidJapanese < StandardError; end

  POLLY = Aws::Polly::Client.new.freeze
  FEMALE_VOICE_ID = "Mizuki".freeze
  MALE_VOICE_ID = "Takumi".freeze
  VOICE_SPEED = "slow" # x-slow, slow, medium, fast, or x-fast

  NON_WORD_NON_SPACE_CHARACTERS = /[^\w\s一-龯ぁ-んァ-ン０-９Ａ-ｚ]/
  INVALID_JAPANESE = /[^ー-龯ぁ-んァ-ン０-９Ａ-ｚ。、！？ー]/

  def initialize(japanese:, filename: nil, allow_all_characters: false, client: POLLY)
    @japanese = japanese
    @filename = filename
    @allow_all_characters = allow_all_characters
    @client = client
  end

  def convert_japanese_to_audio
    raise InvalidJapanese unless is_valid_japanese?

    source = @client
      # .synthesize_speech({
      #   output_format: "mp3",
      #   text: "<speak><prosody rate='#{VOICE_SPEED}'>#{@japanese}</prosody></speak>",
      #   voice_id: FEMALE_VOICE_ID,
      #   text_type: "ssml"
      # }).audio_stream
      # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Polly/Client.html
      # resp = client.start_speech_synthesis_task({
      #   engine: "standard", # accepts standard, neural
      #   language_code: "arb", # accepts arb, cmn-CN, cy-GB, da-DK, de-DE, en-AU, en-GB, en-GB-WLS, en-IN, en-US, es-ES, es-MX, es-US, fr-CA, fr-FR, is-IS, it-IT, ja-JP, hi-IN, ko-KR, nb-NO, nl-NL, pl-PL, pt-BR, pt-PT, ro-RO, ru-RU, sv-SE, tr-TR, en-NZ, en-ZA
      #   lexicon_names: ["LexiconName"],
      #   output_format: "json", # required, accepts json, mp3, ogg_vorbis, pcm
      #   output_s3_bucket_name: "OutputS3BucketName", # required
      #   output_s3_key_prefix: "OutputS3KeyPrefix",
      #   sample_rate: "SampleRate",
      #   sns_topic_arn: "SnsTopicArn",
      #   speech_mark_types: ["sentence"], # accepts sentence, ssml, viseme, word
      #   text: "Text", # required
      #   text_type: "ssml", # accepts ssml, text
      #   voice_id: "Aditi", # required, accepts Aditi, Amy, Astrid, Bianca, Brian, Camila, Carla, Carmen, Celine, Chantal, Conchita, Cristiano, Dora, Emma, Enrique, Ewa, Filiz, Gabrielle, Geraint, Giorgio, Gwyneth, Hans, Ines, Ivy, Jacek, Jan, Joanna, Joey, Justin, Karl, Kendra, Kevin, Kimberly, Lea, Liv, Lotte, Lucia, Lupe, Mads, Maja, Marlene, Mathieu, Matthew, Maxim, Mia, Miguel, Mizuki, Naja, Nicole, Olivia, Penelope, Raveena, Ricardo, Ruben, Russell, Salli, Seoyeon, Takumi, Tatyana, Vicki, Vitoria, Zeina, Zhiyu, Aria, Ayanda
      # })
      # resp = client.get_speech_synthesis_task({
      #   task_id: "TaskId", # required
      # })


    IO.copy_stream(source, destination_file)
    destination_file
  end

  private

  def safe_filename
    @safe_filename ||= begin
      return default_filename if @filename.nil? || @filename.empty?
      safe_filename = File
        .basename(@filename, ".*") # remove file extensions
        .gsub(NON_WORD_NON_SPACE_CHARACTERS, "")
      safe_filename.empty? ? default_filename : safe_filename
    end
  end

  def destination_file
    "public/audio/#{safe_filename}.mp3"
  end

  def default_filename
    # Use a millisecond timestamp as the default filename if the user did not
    # provide a valid filename.
    (Time.now.to_f * 1000).to_i.to_s
  end

  def is_valid_japanese?
    return false if @japanese.nil? || @japanese.empty?
    return false if !@allow_all_characters && @japanese.match?(INVALID_JAPANESE)
    true
  end
end
