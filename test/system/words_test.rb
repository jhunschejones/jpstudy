require "application_system_test_case"

class WordsTest < ApplicationSystemTestCase
  TURBO_WAIT_SECONDS = 0.08.freeze # wait for page to update with turbo_stream

  describe "users with an active trial" do
    test "can view the word list and use filters" do
      login(users(:carl))
      assert_selector "h1", text: "Words"

      # Words before filters appear in the right order
      newest_first = Word.all
        .order(added_to_list_at: :desc).order(created_at: :desc)
        .limit(WordsController::WORDS_PER_PAGE).pluck(:japanese)
      assert_equal newest_first, page.all(".word:not(.skeleton-word) .japanese").collect(&:text), "words with no filter are different than expected"

      # Cards filter limits words to just words without cards
      click_on "Unfiltered"

      sleep TURBO_WAIT_SECONDS

      without_cards = Word.all.cards_not_created
        .order(added_to_list_at: :desc).order(created_at: :desc)
        .limit(WordsController::WORDS_PER_PAGE).pluck(:japanese)
      assert_equal without_cards, page.all(".word:not(.skeleton-word) .japanese").collect(&:text), "words with cards filter are different than expected"

      click_on "Newest first"

      sleep TURBO_WAIT_SECONDS

      # Order and Cards filters work together as expected
      oldest_without_cards_first = Word.all.cards_not_created
        .order(added_to_list_at: :asc).order(created_at: :asc)
        .limit(WordsController::WORDS_PER_PAGE).pluck(:japanese)
      assert_equal oldest_without_cards_first, page.all(".word:not(.skeleton-word) .japanese").collect(&:text), "words with order filter are different than expected"

      click_on "Words without cards"

      sleep TURBO_WAIT_SECONDS

      # Words with order filter appear in the right order
      oldest_first = Word.all
        .order(added_to_list_at: :asc).order(created_at: :asc)
        .limit(WordsController::WORDS_PER_PAGE).pluck(:japanese)
      assert_equal oldest_first, page.all(".word:not(.skeleton-word) .japanese").collect(&:text), "words with order filter are different than expected"

      # Remove all filters
      page.find(".home-link").click

      sleep TURBO_WAIT_SECONDS

      assert_equal newest_first, page.all(".word:not(.skeleton-word) .japanese").collect(&:text), "words with no filter are different than expected"
    end

    test "can view more words by scrolling down the list" do
      login(users(:carl))
      assert_selector "h1", text: "Words"

      # Only loads first page innitially
      first_page = Word.all
        .order(added_to_list_at: :desc).order(created_at: :desc)
        .limit(WordsController::WORDS_PER_PAGE).pluck(:japanese)

      assert_equal first_page, page.all(".word:not(.skeleton-word) .japanese").collect(&:text), "words visible on the first page are different than expected"

      # Scroll to the bottom of the current window
      page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

      sleep TURBO_WAIT_SECONDS

      second_page = Word.all
        .order(added_to_list_at: :desc).order(created_at: :desc)
        .offset(WordsController::WORDS_PER_PAGE)
        .limit(WordsController::WORDS_PER_PAGE)
        .pluck(:japanese)

      third_page = Word.all
        .order(added_to_list_at: :desc).order(created_at: :desc)
        .offset(WordsController::WORDS_PER_PAGE * 2)
        .limit(WordsController::WORDS_PER_PAGE)
        .pluck(:japanese)

      first_three_pages = first_page + second_page + third_page

      # Loads additional pages after user scrolls down
      assert_equal first_three_pages, page.all(".word:not(.skeleton-word) .japanese").collect(&:text), "words visible on the first three pages are different than expected"
    end

    test "can add a word to the word list" do
      login(users(:carl))
      assert_selector "h1", text: "Words"

      click_on "New word"

      # confirm form was loaded with turbo on the same page
      assert_selector "h1", text: "Words"

      fill_in "English", with: "a little more"
      fill_in "Japanese", with: "もう少し"

      click_on "Create Word"

      # confirm still on the words page
      assert_selector "h1", text: "Words"

      # confirm the new word was added
      assert_selector ".word .japanese", text: "もう少し"
      assert_selector ".word .english", text: "a little more"
    end

    test "can modify a word on the word list" do
      word_to_edit = words(:無理)
      updated_english = "#{word_to_edit.english} (updated)"

      login(users(:carl))
      assert_selector "h1", text: "Words"

      page.find("#word_#{word_to_edit.id} .edit a").click

      # confirm form was loaded with turbo on the same page
      assert_selector "h1", text: "Words"

      fill_in "English", with: updated_english

      click_on "Update Word"

      # confirm still on the words page
      assert_selector "h1", text: "Words"

      # confirm the new word was added in the UI
      assert_selector ".word .english", text: updated_english
       # confirm the new word was updated in the DB
      assert_equal updated_english, word_to_edit.reload.english, "the word was not updated in the DB as expected"
    end

    test "can delete a word from the word list" do
      word_to_delete = words(:無理)

      login(users(:carl))
      assert_selector "h1", text: "Words"

      page.accept_confirm do
        page.find("#word_#{word_to_delete.id} .delete button").click
      end

      # confirm still on the words page
      assert_selector "h1", text: "Words"

      # confirm the new word was removed from the UI
      assert_selector ".word .english", text: word_to_delete.japanese, count: 0
      # confirm the new word was deleted in the DB
      assert_nil Word.find_by(japanese: word_to_delete.japanese), "the word was not deleted in the DB as expected"
    end
  end
end
