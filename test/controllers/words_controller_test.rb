require "application_controller_test_case"

class WordsControllerTest < ApplicationControllerTestCase
  describe "#index" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get words_path
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#search" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get search_words_path
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#new" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get new_word_path
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#edit" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get edit_word_path(words(:形容詞))
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#create" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Word.count" do
        post words_path, params: { word: { english: "new", japanese: "新し" } }
      end
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#update" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_changes "Word.find(words(:形容詞).id).english" do
        patch word_path(words(:形容詞)), params: { word: { english: "adjective (grammar)" } }
      end
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#destroy" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Word.count" do
        delete word_path(words(:形容詞))
      end
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#destroy_all" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Word.count" do
        delete destroy_all_words_path
      end
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#in_out" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get in_out_words_path
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#import" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get import_words_path
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#export" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get export_words_path
      assert_redirected_to user_path(users(:elemouse))
    end
  end

  describe "#upload" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      csv_file = fixture_file_upload("test/fixtures/files/words_export_1637975848.csv", "text/csv")
      assert_no_difference "Word.count" do
        post upload_words_path, params: { csv_file: csv_file, csv_includes_headers: true }
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "uploads a valid CSV" do
      login(users(:carl))
      csv_file = fixture_file_upload("test/fixtures/files/words_export_1637975848.csv", "text/csv")
      assert_difference "Word.count", 49 do
        post upload_words_path, params: { csv_file: csv_file, csv_includes_headers: true }
      end
      assert_redirected_to in_out_words_path
      assert_equal "49 new words imported, 1 word already exists.", flash[:success]

      new_word = Word.find_by(japanese: "大人")
      assert_equal "adult", new_word.english
      assert_equal "FF 625", new_word.source_name
      assert new_word.cards_created
      assert_equal users(:carl).id, new_word.user_id
      assert_equal "10/05/2020", new_word.added_to_list_on
    end
  end

  describe "#download" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get download_words_path(format: :csv)
      assert_redirected_to user_path(users(:elemouse))
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
