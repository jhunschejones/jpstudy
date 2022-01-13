require "application_system_test_case"

class KanjiTest < ApplicationSystemTestCase
  describe "users with an active trial" do
    test "can view the next kanji page and mark a kanji as added" do
      login(users(:carl))
      sleep TURBO_WAIT_SECONDS * 4

      visit next_kanji_url
      assert_selector "h1", text: "Next kanji"

      initial_next_kanji = Kanji.next_new_for(user: users(:carl))
      assert_selector ".character", text: initial_next_kanji.character

      click_on "Add"
      sleep TURBO_WAIT_SECONDS

      next_kanji = Kanji.next_new_for(user: users(:carl))
      # make sure we've advanced to a new next kanji and it is visible on the page
      refute_equal initial_next_kanji.character, next_kanji.character
      assert_selector ".character", text: next_kanji.character
    end
  end
end
