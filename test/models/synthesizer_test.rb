require "test_helper"

class SynthesizerTest < ActiveSupport::TestCase
  setup do
    @test_polly_audio_io = Tempfile.new
    @test_polly = Aws::Polly::Client.new(stub_responses: {
      synthesize_speech: stub(audio_stream: @test_polly_audio_io)
    })

    @test_s3_object = stub(put: true, presigned_url: "www.example.com/good morning.mp3")
    @test_s3 = Aws::S3::Resource.new(stub_responses: {
      bucket: stub(object: @test_s3_object)
    })
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
      @test_s3.expects(:bucket).once.returns(stub(object: @test_s3_object))
      @test_s3_object.expects(:put).once.with(body: @test_polly_audio_io)
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
