require "test_helper"

class WordTest < ActiveSupport::TestCase
  describe "validations" do
    it "requires japanese and english attributes to be set" do
      assert_no_difference "Word.count" do
        word = Word.create(user: users(:carl))
        assert_equal ["Japanese can't be blank", "English can't be blank"], word.errors.full_messages
      end
    end

    it "prevents duplicate words for a user" do
      assert_no_difference "Word.count" do
        word = Word.create(
          japanese: users(:carl).words.first.japanese,
          english: users(:carl).words.first.english,
          user: users(:carl)
        )
        assert_equal ["Japanese + English combination already exists"], word.errors.full_messages
      end
    end

    it "prevents users from creating words when they've reached their word limit" do
      users(:carl).update!(word_limit: 20)
      User.reset_counters(users(:carl).id, :words)
      users(:carl).reload

      assert_no_difference "Word.count" do
        word = Word.create(
          japanese: "自己紹介",
          english: "self introduction",
          user: users(:carl)
        )
        assert_equal ["User word limit exceeded"], word.errors.full_messages
      end
    end

    it "requires source name if source refrence is set" do
      assert_no_difference "Word.count" do
        word = Word.create(
          japanese: "自己紹介",
          english: "self introduction",
          user: users(:carl),
          source_reference: "Chapter 12"
        )
        assert_equal ["Source name is required for source reference"], word.errors.full_messages
      end
    end
  end

  it "broadcasts async word and kanji stream events on create" do
    perform_enqueued_jobs do
      assert_broadcasts users(:carl).words_stream_name, 1 do
        assert_broadcasts users(:carl).kanji_stream_name, 1 do
          Word.create!(japanese: "自己紹介", english: "self introduction", user: users(:carl), checked_at: Time.now.utc)
        end
      end
    end
    assert_performed_jobs 2
  end

  it "broadcasts async word and kanji stream events on update" do
    perform_enqueued_jobs do
      assert_broadcasts users(:carl).words_stream_name, 1 do
        assert_broadcasts users(:carl).kanji_stream_name, 1 do
          words(:形容詞).update!(english: "updated")
        end
      end
    end
    assert_performed_jobs 2
  end

  it "broadcasts synchronous word and kanji stream events on destroy" do
    assert_broadcasts users(:carl).words_stream_name, 1 do
      assert_broadcasts users(:carl).kanji_stream_name, 1 do
        words(:形容詞).destroy
      end
    end
  end
end
