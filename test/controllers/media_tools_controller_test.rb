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
    setup do
      Synthesizer::POLLY.stubs(synthesize_speech: stub(audio_stream: Tempfile.new))
      Synthesizer::S3.stubs(
        bucket: stub(object:
          stub(put: true, presigned_url: "www.example.com/good morning.mp3")
        )
      )
    end

    it "requires subscription or trial to access" do
      login(users(:elemouse))
      post japanese_to_audio_media_tools_path, params: { japanese: "おはいよう" }
      assert_redirected_to user_path(users(:elemouse))
    end

    it "synthesizes an audio file, uploads to S3 and redirects with audio_url and filename" do
      login(users(:carl))
      post japanese_to_audio_media_tools_path, params: { japanese: "おはいよう", english: "good morning" }
      assert_redirected_to audio_media_tools_path(
        audio_url: CGI.escape("www.example.com/good morning.mp3"), filename: "good morning.mp3"
      )
    end

    it "increments audio_conversions_used_this_month for the current user" do
      login(users(:carl))
      assert_difference "User.find(users(:carl).id).audio_conversions_used_this_month", 1 do
        post japanese_to_audio_media_tools_path, params: { japanese: "おはいよう", english: "good morning" }
      end
    end

    it "prevents users who have exceeded their montly limit from creating new audio files" do
      login(users(:carl))
      users(:carl).update!(audio_conversions_used_this_month: 500)
      post japanese_to_audio_media_tools_path, params: { japanese: "おはいよう", english: "good morning" }
      assert_redirected_to audio_media_tools_path
      assert_equal "Users are limited to 500 conversions per month. Please contact support if you need additional audio conversions.", flash[:alert]
    end

    it "prevents audio file creation for strings longer than limit" do
      login(users(:carl))
      post japanese_to_audio_media_tools_path, params: { japanese: "16日にちの地震じしんで、宮城県みやぎけん白石しろいし市しを走はしっていた東北新幹線とうほくしんかんせんが脱線だっせんしました。それ以外いがいの場所ばしょでも線路せんろや電柱でんちゅうなどが壊こわれました。17日にちから東北新幹線とうほくしんかんせんは那須塩原なすしおばら駅えきと盛岡駅もりおかえきの間あいだで運転うんてんすることができなくなっています。このため、東京駅とうきょうえきと那須塩原なすしおばら駅えきの間あいだ、盛岡駅もりおかえきと新函館しんはこだて北斗駅ほくとえきの間あいだで、数かずを少すくなくして運転うんてんしています。", english: "good morning" }
      assert_redirected_to audio_media_tools_path
      assert_equal "Input text must be no longer than 135 characters", flash[:notice]
    end
  end
end
