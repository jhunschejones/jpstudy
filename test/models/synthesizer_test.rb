require "test_helper"

class SynthesizerTest < ActiveSupport::TestCase
  setup do
    @test_polly_audio_io = Tempfile.new
    @test_polly = Aws::Polly::Client.new(stub_responses: {
      synthesize_speech: stub(audio_stream: @test_polly_audio_io)
    })

    @test_s3_bucket = stub(put_object: @test_s3_object)
    @test_s3_object = stub(put: true, presigned_url: "www.example.com/good morning.mp3")
    @test_s3 = Aws::S3::Resource.new(stub_responses: { bucket: @test_s3_bucket })
  end

  describe "#convert_japanese_to_audio" do
    setup do
      @synthesizer = Synthesizer.new(
        japanese: "おはよう",
        english: "good morning",
        user: users(:carl),
        polly: @test_polly,
        s3: @test_s3
      )
    end

    it "uses aws polly to synthesize text to speach" do
      @test_polly.expects(:synthesize_speech).once.returns(stub(audio_stream: Tempfile.new))
      @synthesizer.convert_japanese_to_audio
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
      @synthesizer.convert_japanese_to_audio
    end

    it "returns expected array values for audio_url and filename" do
      response = @synthesizer.convert_japanese_to_audio
      assert_equal 2, response.size
      assert_match /https:\/\/jpstudy.s3.us-stubbed-1.amazonaws.com\/polly\/#{users(:carl).hashid}\//, response.first
      assert_equal "good morning.mp3", response.last
    end
  end
end
