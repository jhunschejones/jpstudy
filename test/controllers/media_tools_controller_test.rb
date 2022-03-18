require "application_controller_test_case"

class KanjiControllerTest < ApplicationControllerTestCase
  describe "#audio" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get audio_media_tools_path
      assert_redirected_to user_path(users(:elemouse))
    end

    it "returns the audio tools page" do
      login(users(:carl))
      get audio_media_tools_path
      assert_response :success
    end
  end

  describe "#japanese_to_audio" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      post japanese_to_audio_media_tools_path, params: { japanese: "おはいよう" }
      assert_redirected_to user_path(users(:elemouse))
    end

    it "synthesizes an audio file, uploads to S3 and redirects with audio_url and filename" do
      Synthesizer::POLLY.stubs(synthesize_speech: stub(audio_stream: Tempfile.new))
      Synthesizer::S3.stubs(
        bucket: stub(object:
          stub(put: true, presigned_url: "www.example.com/good morning.mp3")
        )
      )
      login(users(:carl))
      post japanese_to_audio_media_tools_path, params: { japanese: "おはいよう", english: "good morning" }
      assert_redirected_to audio_media_tools_path(
        audio_url: CGI.escape("www.example.com/good morning.mp3"), filename: "good morning.mp3"
      )
    end
  end
end
