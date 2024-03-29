require "application_controller_test_case"

class KanjiControllerTest < ApplicationControllerTestCase
  describe "#audio" do
    setup do
      Synthesizer::S3.stubs(
        bucket: stub(object:
          stub(presigned_url: "www.example.com/good+morning.mp3")
        )
      )
    end

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

    it "shows the latest conversion when one exists" do
      Rails.stubs(:cache).returns(ActiveSupport::Cache.lookup_store(:memory_store))
      Rails.cache.clear

      Rails.cache.write(
        "#{users(:carl).hashid}/last_converted_audio_file",
        "polly/#{users(:carl).hashid}/good morning.mp3"
      )
      login(users(:carl))
      get audio_media_tools_path
      assert_response :success
      assert_select ".download-link", text: "good morning.mp3"
    end

    it "remembers the position of the use_neural_voice switch" do
      login(users(:carl))
      get audio_media_tools_path(use_neural_voice: true)
      assert_response :success
      assert_select ".neural-voice-field input[name='use_neural_voice'][checked]", 1
    end
  end

  describe "#japanese_to_audio" do
    setup do
      Synthesizer::POLLY.stubs(synthesize_speech: stub(audio_stream: Tempfile.new))
      Synthesizer::S3.stubs(
        bucket: stub(put_object:
          stub(put: true)
        )
      )
    end

    it "requires subscription or trial to access" do
      login(users(:elemouse))
      post japanese_to_audio_media_tools_path, params: { japanese: "おはよう" }
      assert_redirected_to user_path(users(:elemouse))
    end

    it "redirects to the audio page" do
      login(users(:carl))
      post japanese_to_audio_media_tools_path, params: { japanese: "おはよう", english: "good morning" }
      assert_redirected_to audio_media_tools_path
    end

    it "keeps the use_neural_voice param when redirecting to audio page" do
      login(users(:carl))
      post japanese_to_audio_media_tools_path, params: { japanese: "おはよう", english: "good morning", use_neural_voice: true }
      assert_redirected_to audio_media_tools_path(use_neural_voice: true)
    end

    it "stores the s3 key for the last converted audio file" do
      Rails.stubs(:cache).returns(ActiveSupport::Cache.lookup_store(:memory_store))
      Rails.cache.clear

      login(users(:carl))
      assert_nil Rails.cache.read("#{users(:carl).hashid}/last_converted_audio_file")

      post japanese_to_audio_media_tools_path, params: { japanese: "おはよう", english: "good morning" }

      assert_equal "polly/#{users(:carl).hashid}/good morning.mp3", Rails.cache.read("#{users(:carl).hashid}/last_converted_audio_file")
    end

    it "increments audio_conversions_used_this_month for the current user" do
      login(users(:carl))
      assert_difference "User.find(users(:carl).id).audio_conversions_used_this_month", 1 do
        post japanese_to_audio_media_tools_path, params: { japanese: "おはよう", english: "good morning" }
      end
    end

    it "prevents users who have exceeded their montly limit from creating new audio files" do
      login(users(:carl))
      users(:carl).update!(audio_conversions_used_this_month: 500)
      post japanese_to_audio_media_tools_path, params: { japanese: "おはよう", english: "good morning" }
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
