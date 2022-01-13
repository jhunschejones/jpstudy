require "test_helper"

class KanjiTest < ActiveSupport::TestCase
  describe ".all_new_for" do
    it "returns all new kanjis for a user" do
      carls_new_kanji = Kanji.all_new_for(user: users(:carl))
      assert carls_new_kanji.first.is_a?(Kanji)
      assert_equal ["寝", "教", "婚", "約", "大", "切", "使", "如", "何", "言", "短", "頃", "体", "無", "理", "然", "回", "実", "陰", "様", "段", "調", "子", "悪"], carls_new_kanji.map(&:character)
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
end
