require "application_controller_test_case"

class WordsControllerTest < ApplicationControllerTestCase
  describe "#index" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get words_path(users(:elemouse))
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not return the word list for another user" do
      login(users(:daisy))
      get words_path(users(:carl))
      assert_response :not_found
    end

    it "returns the words list page" do
      login(users(:carl))
      get words_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Words"
    end

    it "filters results by source_name" do
      login(users(:carl))
      get words_path(users(:carl), source_name: "FF 625")
      assert_response :success
      assert_select ".word", count: 2
    end

    it "filters results by search" do
      login(users(:carl))
      get words_path(users(:carl), search: "short")
      assert_response :success
      assert_select ".word", count: 2
    end

    it "respects order param when oldest_first" do
      login(users(:carl))
      get words_path(users(:carl), order: "oldest_first")
      assert_response :success
      assert_select ".word" do |words|
        assert_select words.first, ".japanese", text: "形容詞"
      end
    end

    it "filters results to words not checked off" do
      login(users(:carl))
      get words_path(users(:carl), filter: "not_checked_off")
      assert_response :success
      assert_select ".word", count: 2
    end
  end

  describe "#search" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get search_words_path(users(:elemouse))
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not return the word search for another user" do
      login(users(:daisy))
      get search_words_path(users(:carl))
      assert_response :not_found
    end

    it "returns the word search form" do
      login(users(:carl))
      get search_words_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Word search"
    end
  end

  describe "#count" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get count_words_path(users(:elemouse), filter: "not_checked_off")
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not return the word count for another user" do
      login(users(:daisy))
      get count_words_path(users(:carl), filter: "not_checked_off")
      assert_response :not_found
    end

    it "returns the users word count taking into account filter params" do
      login(users(:carl))
      get count_words_path(users(:carl), filter: "not_checked_off")
      assert_response :success
      json_response = JSON.parse(response.body)
      expected_count = users(:carl).words.not_checked_off.count
      assert_equal expected_count, json_response["wordsCount"]
    end
  end

  describe "#show" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get word_path(users(:elemouse), words(:形容詞))
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not return the word details page for another users word" do
      login(users(:daisy))
      get word_path(users(:carl), words(:形容詞))
      assert_response :not_found
    end

    it "returns the word details page" do
      login(users(:carl))
      get word_path(users(:carl), words(:形容詞))
      assert_response :success
      assert_select ".page-title", "Word details"
      assert_select ".japanese", words(:形容詞).japanese
    end
  end

  describe "#new" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get new_word_path(users(:elemouse))
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not return the new page for another user" do
      login(users(:daisy))
      get new_word_path(users(:carl))
      assert_response :not_found
    end

    it "returns the new word form with turbo disabled" do
      login(users(:carl))
      get new_word_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Add a new word"
      assert_select "form[data-turbo='false']"
    end
  end

  describe "#edit" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get edit_word_path(users(:elemouse), words(:形容詞))
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not return the edit page for another users word" do
      login(users(:daisy))
      get edit_word_path(users(:carl), words(:形容詞))
      assert_response :not_found
    end

    it "returns the word edit form with turbo disabled" do
      login(users(:carl))
      get edit_word_path(users(:carl), words(:形容詞))
      assert_response :success
      assert_select ".page-title", "Editing word"
      assert_select "form[data-turbo='false']"
    end
  end

  describe "#create" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Word.count" do
        post words_path(users(:elemouse)), params: { word: { english: "new", japanese: "新し" } }
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not create a word for another user" do
      login(users(:daisy))
      assert_no_difference "Word.count" do
        post words_path(users(:carl)), params: { word: { english: "new", japanese: "新し" } }
      end
      assert_response :not_found
    end

    it "creates a word with an added_to_list_at timestamp" do
      login(users(:carl))
      freeze_time do
        assert_difference "Word.count", 1 do
          post words_path(users(:carl)), params: { word: { english: "new", japanese: "新し" } }
        end
        assert_equal "新し", Word.last.japanese
        assert_equal Time.now.utc, Word.last.added_to_list_at
      end
    end

    it "leaves optional attributes as nil when not provided" do
      login(users(:carl))
      post words_path(users(:carl)), params: { word: { english: "new", japanese: "新し" } }
      assert_nil Word.last.checked_off_at
      assert_nil Word.last.note
      assert_nil Word.last.source_name
      assert_nil Word.last.source_reference
    end

    it "redirects to the word list page with the new word for html requests" do
      login(users(:carl))
      post words_path(users(:carl)), params: { word: { english: "new", japanese: "新し" } }
      follow_redirect!
      assert_equal path, words_path(users(:carl))
      assert_select ".japanese", "新し"
    end

    it "returns turbo stream response for turbo requests" do
      login(users(:carl))
      post words_path(users(:carl), format: :turbo_stream), params: { word: { english: "new", japanese: "新し" } }
      assert_response :success
      assert_select ".japanese", "新し"
    end
  end

  describe "#update" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_changes "Word.find(words(:形容詞).id).english" do
        patch word_path(users(:elemouse), words(:キツネ)), params: { word: { english: "adjective (grammar)" } }
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "prevents users from modifing another users word" do
      login(users(:daisy))
      assert_no_changes "Word.find(words(:形容詞).id).english" do
        patch word_path(users(:carl), words(:形容詞)), params: { word: { english: "adjective (grammar)" } }
      end
      assert_response :not_found
    end

    it "updates the word and redirects for html request" do
      login(users(:carl))
      assert_changes "Word.find(words(:形容詞).id).english" do
        patch word_path(users(:carl), words(:形容詞)), params: { word: { english: "adjective (grammar)" } }
      end
      follow_redirect!
      assert_equal path, word_path(users(:carl), words(:形容詞))
    end

    it "updates the word and sends turbo stream response for turbo request" do
      login(users(:carl))
      assert_changes "Word.find(words(:形容詞).id).english" do
        patch word_path(users(:carl), words(:形容詞), format: :turbo_stream), params: { word: { english: "adjective (grammar)" } }
      end
      assert_response :success
      assert_select "span.english", text: "adjective (grammar)"
    end
  end

  describe "#destroy" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Word.count" do
        delete word_path(users(:elemouse), words(:キツネ))
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "prevents a user from deleting another users word" do
      login(users(:daisy))
      assert_no_difference "Word.count" do
        delete word_path(users(:carl), words(:形容詞))
      end
      assert_response :not_found
    end

    it "deletes the word and redirects for html requests" do
      login(users(:carl))
      assert_difference "Word.count", -1 do
        delete word_path(users(:carl), words(:形容詞))
      end
      follow_redirect!
      assert_equal path, words_path
    end

    it "deletes the word and sends turbo stream response for turbo requests" do
      login(users(:carl))
      assert_difference "Word.count", -1 do
        delete word_path(users(:carl), words(:形容詞), format: :turbo_stream)
      end
      assert_response :success
      assert_select "turbo-stream[action='remove'][target='word_#{words(:形容詞).id}']"
    end
  end

  describe "#destroy_all" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Word.count" do
        delete destroy_all_words_path(users(:elemouse))
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not delete other users words" do
      login(users(:daisy))
      assert_no_difference "Word.count" do
        delete destroy_all_words_path(users(:carl))
      end
      assert_response :not_found
    end

    it "deletes all the users words" do
      login(users(:carl))
      delete destroy_all_words_path(users(:carl))
      assert_equal 0, users(:carl).words.count
    end

    it "redirects with a user message" do
      login(users(:carl))
      words_count = users(:carl).words.count
      delete destroy_all_words_path(users(:carl))
      assert_redirected_to in_out_user_path(users(:carl))
      assert_equal "#{words_count} words deleted.", flash[:success]
    end
  end

  describe "#toggle_checked_off" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_changes "Word.find(words(:形容詞).id).checked_off" do
        post word_toggle_checked_off_path(users(:elemouse), words(:形容詞))
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "prevents users from modifying other users words" do
      login(users(:daisy))
      assert_no_changes "Word.find(words(:形容詞).id).checked_off" do
        post word_toggle_checked_off_path(users(:carl), words(:形容詞))
      end
      assert_response :not_found
    end

    it "toggles the checked_off attribute for the word" do
      login(users(:carl))
      assert_changes "Word.find(words(:形容詞).id).checked_off" do
        post word_toggle_checked_off_path(users(:carl), words(:形容詞))
      end
    end

    it "redirects the word details page for html requests" do
      login(users(:carl))
      post word_toggle_checked_off_path(users(:carl), words(:形容詞))
      follow_redirect!
      assert_select ".japanese", words(:形容詞).japanese
    end

    it "returns the updated word for turbo requests" do
      login(users(:carl))
      post word_toggle_checked_off_path(users(:carl), words(:形容詞), format: :turbo_stream)
      assert_response :success
      assert_select ".japanese", words(:形容詞).japanese
    end

    it "returns a message when word target has been reached" do
      login(users(:carl))
      users(:carl).update!(daily_word_target: 1)
      post word_toggle_checked_off_path(users(:carl), words(:よく寝た))
      assert_equal 1, users(:carl).words.where(checked_off_at: Date.today.all_day).size
      assert_equal "🎉 You reached your daily word target!", flash[:success]
    end

    it "does not return a message when word target has been exceeded" do
      login(users(:carl))
      users(:carl).update!(daily_word_target: 1)
      Word.create!(japanese: "自己紹介", english: "self introduction", user: users(:carl), checked_off_at: Time.now.utc)
      post word_toggle_checked_off_path(users(:carl), words(:よく寝た))
      assert_equal 2, users(:carl).words.where(checked_off_at: Date.today.all_day).size
      refute flash[:success]
    end
  end

  describe "#toggle_starred" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_changes "Word.find(words(:形容詞).id).starred" do
        post word_toggle_starred_path(users(:elemouse), words(:形容詞))
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "prevents users from modifying other users words" do
      login(users(:daisy))
      assert_no_changes "Word.find(words(:形容詞).id).starred" do
        post word_toggle_starred_path(users(:carl), words(:形容詞))
      end
      assert_response :not_found
    end

    it "toggles the starred attribute for the word" do
      login(users(:carl))
      assert_changes "Word.find(words(:形容詞).id).starred" do
        post word_toggle_starred_path(users(:carl), words(:形容詞))
      end
    end

    it "redirects the word details page for html requests" do
      login(users(:carl))
      post word_toggle_starred_path(users(:carl), words(:形容詞))
      follow_redirect!
      assert_select ".japanese", words(:形容詞).japanese
    end

    it "returns the updated word for turbo requests" do
      login(users(:carl))
      post word_toggle_starred_path(users(:carl), words(:形容詞), format: :turbo_stream)
      assert_response :success
      assert_select ".japanese", words(:形容詞).japanese
    end
  end

  describe "#import" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get import_words_path(users(:elemouse))
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not return the import page for another user" do
      login(users(:daisy))
      get import_words_path(users(:carl))
      assert_response :not_found
    end

    it "returns the words import page" do
      login(users(:carl))
      get import_words_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Import words"
    end
  end

  describe "#export" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get export_words_path(users(:elemouse))
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not return the export page for another user" do
      login(users(:daisy))
      get export_words_path(users(:carl))
      assert_response :not_found
    end

    it "returns the words export page" do
      login(users(:carl))
      get export_words_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Export your word list"
    end
  end

  describe "#upload" do
    setup do
      @csv_file = fixture_file_upload("test/fixtures/files/words_export_1637975848.csv", "text/csv")
    end

    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Word.count" do
        post upload_words_path(users(:elemouse)), params: { csv_file: @csv_file, csv_includes_headers: true }
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not allow a user to upload words for another user" do
      login(users(:daisy))
      assert_no_difference "Word.count" do
        post upload_words_path(users(:carl)), params: { csv_file: @csv_file, csv_includes_headers: true }
      end
      assert_response :not_found
    end

    it "uploads a valid CSV" do
      login(users(:carl))
      assert_difference "Word.count", 49 do
        post upload_words_path(users(:carl)), params: { csv_file: @csv_file, csv_includes_headers: true }
      end
      assert_redirected_to in_out_user_path(users(:carl))
      assert_equal "49 new words imported, 1 word already exists.", flash[:success]

      new_word = Word.find_by(japanese: "大人")
      assert_equal "adult", new_word.english
      assert_equal "FF 625", new_word.source_name
      assert new_word.starred
      assert new_word.checked_off
      assert_equal users(:carl).id, new_word.user_id
      assert_equal "10/05/2020", new_word.added_to_list_on
    end

    it "does not trigger infinity websocket updates" do
      login(users(:carl))
      assert_no_enqueued_jobs do
        post upload_words_path(users(:carl)), params: { csv_file: @csv_file, csv_includes_headers: true }
      end
    end
  end

  describe "#download" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get download_words_path(users(:elemouse), format: :csv)
      assert_redirected_to user_path(users(:elemouse))
    end

    it "does not allow a user to download another users words" do
      login(users(:daisy))
      get download_words_path(users(:carl), format: :csv)
      assert_response :not_found
    end

    it "downloads a csv" do
      login(users(:carl))
      freeze_time do
        get download_words_path(users(:carl), format: :csv)
        assert_response :success
        assert_equal "text/csv", response.headers["Content-Type"]
        assert response.headers["Content-Disposition"].include?("attachment; filename=\"words_export_#{Time.now.utc.to_i}.csv\""), "likely missing expected CSV file in response"
      end
    end
  end

  describe "#date_or_time_from" do
    it "parses a short month, short day, short year datetime string" do
      assert_equal Date.new(2021, 1, 3), WordsController.new.send(:date_or_time_from, "1/3/21")
    end

    it "parses a short month, long day, short year datetime string" do
      assert_equal Date.new(2021, 1, 15), WordsController.new.send(:date_or_time_from, "1/15/21")
    end

    it "parses a long month, long day, short year datetime string" do
      assert_equal Date.new(2021, 10, 15), WordsController.new.send(:date_or_time_from, "10/15/21")
    end

    it "parses a short month, short day, long year datetime string" do
      assert_equal Date.new(2021, 1, 3), WordsController.new.send(:date_or_time_from, "1/3/2021")
    end

    it "parses a short month, long day, long year datetime string" do
      assert_equal Date.new(2021, 1, 15), WordsController.new.send(:date_or_time_from, "1/15/2021")
    end

    it "parses a long month, long day, long year datetime string" do
      assert_equal Date.new(2021, 10, 15), WordsController.new.send(:date_or_time_from, "10/15/2021")
    end

    it "parses an integer timestamp" do
      assert_equal Word.last.created_at.to_time.change(usec: 0), WordsController.new.send(:date_or_time_from, Word.last.created_at.to_i)
    end

    it "parses a string timestamp" do
      assert_equal Word.last.created_at.to_time.change(usec: 0), WordsController.new.send(:date_or_time_from, Word.last.created_at.to_s)
    end

    it "raises on invalid date or time" do
      assert_raises WordsController::InvalidDateOrTime, "space_cats" do
        WordsController.new.send(:date_or_time_from, "space_cats")
      end
    end
  end
end
