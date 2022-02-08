require "test_helper"

class KanjiTest < ActiveSupport::TestCase
  describe "validations" do
    it "prevents english characters" do
      assert_no_difference "Kanji.count" do
        kanji = Kanji.create(user: users(:carl), character: "A")
        assert_equal ["Character is invalid"], kanji.errors.full_messages
      end
    end

    it "prevents kana characters" do
      assert_no_difference "Kanji.count" do
        kanji = Kanji.create(user: users(:carl), character: "ね")
        assert_equal ["Character is invalid"], kanji.errors.full_messages
      end
    end

    it "prevents duplicate characters" do
      assert_no_difference "Kanji.count" do
        kanji = Kanji.create(user: users(:carl), character: users(:carl).kanji.last.character)
        assert_equal ["Character has already been taken"], kanji.errors.full_messages
      end
    end

    it "prevents users from creating kanji when they've reached their kanji limit" do
      users(:carl).update!(kanji_limit: users(:carl).kanji.count)
      User.reset_counters(users(:carl).id, :kanji)
      users(:carl).reload

      assert_no_difference "Kanji.count" do
        kanji = Kanji.create(user: users(:carl), character: "寝")
        assert_equal ["User kanji limit exceeded"], kanji.errors.full_messages
      end
    end

    it "prevents invalid statuses" do
      assert_no_difference "Kanji.count" do
        kanji = Kanji.create(user: users(:carl), character: "寝", status: "space_cats")
        assert_equal ["Status status must be either 'added', or 'skipped'"], kanji.errors.full_messages
      end
    end
  end

  describe ".all_new_for" do
    it "returns all new kanjis for a user" do
      carls_new_kanji = Kanji.all_new_for(user: users(:carl))
      assert carls_new_kanji.first.is_a?(Kanji)
      assert_equal ["寝", "教", "婚", "約", "大", "切", "使", "如", "何", "言", "短", "頃", "体", "無", "理", "然", "回", "実", "陰", "様", "段", "調", "子", "悪"].sort, carls_new_kanji.map(&:character).sort
    end
  end

  describe ".next_new_for" do
    it "returns the next new kanji for a user" do
      assert Kanji.next_new_for(user: users(:carl)).is_a?(Kanji)
      assert_equal "寝", Kanji.next_new_for(user: users(:carl)).character
    end

    it "returns nil when there is no next kanji" do
      assert_nil Kanji.next_new_for(user: users(:elemouse))
    end
  end

  it "broadcasts async kanji stream events on create" do
    perform_enqueued_jobs do
      assert_broadcasts users(:carl).kanji_stream_name, 1 do
        Kanji.create!(user: users(:carl), character: "礼", status: Kanji::ADDED_STATUS, added_to_list_at: Time.now.utc)
      end
    end
    assert_performed_jobs 1
  end

  it "broadcasts async kanji stream events on update" do
    perform_enqueued_jobs do
      assert_broadcasts users(:carl).kanji_stream_name, 1 do
        kanji(:形).update!(status: Kanji::SKIPPED_STATUS)
      end
    end
    assert_performed_jobs 1
  end

  it "broadcasts synchronous kanji stream events on destroy" do
    assert_broadcasts users(:carl).kanji_stream_name, 1 do
      kanji(:形).destroy
    end
  end
end
