require "test_helper"

class SynthesizerTest < ActiveSupport::TestCase
  setup do
    @test_polly_audio_io = Tempfile.new
    @test_polly = Aws::Polly::Client.new(stub_responses: {
      synthesize_speech: stub(audio_stream: @test_polly_audio_io)
    })

    @test_s3_bucket = stub(put_object: @test_s3_object, object: @test_s3_object)
    @test_s3_object = stub(put: true, presigned_url: "www.example.com/good morning.mp3")
    @test_s3 = Aws::S3::Resource.new(stub_responses: { bucket: @test_s3_bucket })
  end

  describe "#convert_japanese_to_audio" do
    setup do
      @synthesizer = Synthesizer.new(
        user: users(:carl),
        polly: @test_polly,
        s3: @test_s3
      )
    end

    it "uses aws polly to synthesize text to speach" do
      @test_polly.expects(:synthesize_speech).once.returns(stub(audio_stream: Tempfile.new))
      @synthesizer.convert_japanese_to_audio(
        japanese: "おはよう",
        english: "good morning",
      )
    end

    it "uploads resulting IO object to s3" do
      @test_s3.expects(:bucket).once.returns(@test_s3_bucket)
      @test_s3_bucket.expects(:put_object).once
        .with(
          body: @test_polly_audio_io,
          key: "polly/#{users(:carl).hashid}/good morning.mp3",
          content_type: "audio/mpeg",
          tagging: "media-source=polly"
        )
        .returns(@test_s3_object)
      @synthesizer.convert_japanese_to_audio(
        japanese: "おはよう",
        english: "good morning",
      )
    end

    it "returns the s3 file key" do
      response = @synthesizer.convert_japanese_to_audio(
        japanese: "おはよう",
        english: "good morning",
      )
      assert_equal "polly/#{users(:carl).hashid}/good morning.mp3", response
    end
  end

  describe "#url_for_japanese_audio" do
    setup do
      @synthesizer = Synthesizer.new(
        user: users(:carl),
        polly: @test_polly,
        s3: @test_s3
      )
    end

    it "gets a presigned URL from s3" do
      @test_s3.expects(:bucket).once.returns(@test_s3_bucket)
      @test_s3_bucket.expects(:object).once
        .with("polly/#{users(:carl).hashid}/good morning.mp3")
        .returns(@test_s3_object)
      @synthesizer.url_for_japanese_audio(s3_key: "polly/#{users(:carl).hashid}/good morning.mp3")
    end

    it "returns the expected tuple of filename and audio_url" do
      response = @synthesizer.url_for_japanese_audio(s3_key: "polly/#{users(:carl).hashid}/good morning.mp3")
      assert_equal 2, response.size
      assert_equal "good morning.mp3", response.first
      assert_match /filename%3Dgood%20morning.mp3/, response.last
    end
  end
end
