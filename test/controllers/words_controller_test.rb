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
  end

  describe "#download" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get download_words_path(format: :csv)
      assert_redirected_to user_path(users(:elemouse))
    end
  end
end
