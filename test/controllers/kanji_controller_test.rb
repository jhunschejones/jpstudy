require "application_controller_test_case"

class KanjiControllerTest < ApplicationControllerTestCase
  describe "#next" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get next_kanji_path
      assert_redirected_to user_path(users(:elemouse))
    end

    it "returns the 'next kanji' page with the next character to add" do
      login(users(:carl))
      get next_kanji_path
      assert_response :success
      assert_select ".character", "寝"
    end
  end

  describe "#create" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Kanji.count" do
        post kanji_path, params: { kanji: { character: "竜", status: Kanji::ADDED_STATUS } }
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "adds a kanji and redirects to the next kanji page" do
      login(users(:carl))
      assert_difference "Kanji.added.count", 1 do
        post kanji_path, params: { kanji: { character: "竜", status: Kanji::ADDED_STATUS } }
      end
      follow_redirect!
      assert_equal path, next_kanji_path
    end

    it "skips a kanji and redirects to the next kanji page" do
      login(users(:carl))
      assert_difference "Kanji.where(status: Kanji::SKIPPED_STATUS).count", 1 do
        post kanji_path, params: { kanji: { character: "竜", status: Kanji::SKIPPED_STATUS } }
      end
      follow_redirect!
      assert_equal path, next_kanji_path
    end

    it "doesn't allow duplicate kanji" do
      login(users(:carl))
      assert_no_difference "Kanji.added.count" do
        post kanji_path, params: { kanji: { character: kanji(:形).character, status: kanji(:形).status } }
      end
      follow_redirect!
      assert_equal path, next_kanji_path
      assert_equal "Unable to save kanji: Character has already been taken", flash[:alert]
    end

    it "returns a message when kanji target has been reached" do
      login(users(:carl))
      users(:carl).update!(daily_kanji_target: 1)
      users(:carl).reload
      post kanji_path, params: { kanji: { character: "竜", status: Kanji::ADDED_STATUS } }
      follow_redirect!
      assert_equal "🎉 You reached your daily kanji target!", flash[:success]
    end

    it "does not return a message when kanji target has been exceeded" do
      login(users(:carl))
      users(:carl).update!(daily_kanji_target: 1)
      users(:carl).reload
      Kanji.create(user: users(:carl), character: "礼", status: Kanji::ADDED_STATUS, added_to_list_at: Time.now.utc)
      post kanji_path, params: { kanji: { character: "竜", status: Kanji::ADDED_STATUS } }
      follow_redirect!
      refute flash[:success]
    end
  end

  describe "#destroy" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Kanji.count" do
        delete delete_kanji_path(kanji(:形))
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "deletes a kanji" do
      login(users(:carl))
      assert_difference "Kanji.count", -1 do
        delete delete_kanji_path(kanji(:形))
      end
    end
  end

  describe "#import" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get import_kanji_path
      assert_redirected_to user_path(users(:elemouse))
    end

    it "returns the 'import kanji' page" do
      login(users(:carl))
      get import_kanji_path
      assert_response :success
      assert_select ".page-title", "Import kanji"
    end
  end

  describe "#upload" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      csv_file = fixture_file_upload("test/fixtures/files/kanji_export_1639956633.csv", "text/csv")
      assert_no_difference "Word.count" do
        post upload_kanji_path, params: { csv_file: csv_file, csv_includes_headers: true }
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "uploads a valid CSV" do
      login(users(:carl))
      csv_file = fixture_file_upload("test/fixtures/files/kanji_export_1639956633.csv", "text/csv")
      assert_difference "Kanji.count", 46 do
        post upload_kanji_path, params: { csv_file: csv_file, csv_includes_headers: true }
      end
      assert_redirected_to in_out_user_path(users(:carl))
      assert_equal "46 new kanji imported, 3 kanji already exist.", flash[:success]

      new_kanji = Kanji.find_by(character: "億")
      assert_equal "億", new_kanji.character
      assert_equal "added", new_kanji.status
      assert_equal users(:carl).id, new_kanji.user_id
      assert_equal "12/17/2021", new_kanji.added_to_list_on
    end
  end

  describe "#export" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get export_kanji_path
      assert_redirected_to user_path(users(:elemouse))
    end

    it "returns the 'export kanji' page" do
      login(users(:carl))
      get export_kanji_path
      assert_response :success
      assert_select ".page-title", "Export your kanji"
    end
  end

  describe "#download" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      get download_kanji_path(format: :csv)
      assert_redirected_to user_path(users(:elemouse))
    end

    it "downloads a csv" do
      login(users(:carl))
      freeze_time do
        get download_kanji_path(format: :csv)
        assert_response :success
        assert_equal "text/csv", response.headers["Content-Type"]
        assert response.headers["Content-Disposition"].include?("attachment; filename=\"kanji_export_#{Time.now.utc.to_i}.csv\""), "likely missing expected CSV file in response"
      end
    end
  end

  describe "#destroy_all" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Kanji.count" do
        delete destroy_all_kanji_path
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "deletes all the users kanji" do
      login(users(:carl))
      delete destroy_all_kanji_path
      assert_equal 0, users(:carl).kanji.count
    end
  end

  describe "#date_or_time_from" do
    it "parses a short month, short day, short year datetime string" do
      assert_equal Date.new(2021, 1, 3), KanjiController.new.send(:date_or_time_from, "1/3/21")
    end

    it "parses a short month, long day, short year datetime string" do
      assert_equal Date.new(2021, 1, 15), KanjiController.new.send(:date_or_time_from, "1/15/21")
    end

    it "parses a long month, long day, short year datetime string" do
      assert_equal Date.new(2021, 10, 15), KanjiController.new.send(:date_or_time_from, "10/15/21")
    end

    it "parses a short month, short day, long year datetime string" do
      assert_equal Date.new(2021, 1, 3), KanjiController.new.send(:date_or_time_from, "1/3/2021")
    end

    it "parses a short month, long day, long year datetime string" do
      assert_equal Date.new(2021, 1, 15), KanjiController.new.send(:date_or_time_from, "1/15/2021")
    end

    it "parses a long month, long day, long year datetime string" do
      assert_equal Date.new(2021, 10, 15), KanjiController.new.send(:date_or_time_from, "10/15/2021")
    end

    it "parses an integer timestamp" do
      assert_equal Word.last.created_at.to_time.change(usec: 0), KanjiController.new.send(:date_or_time_from, Word.last.created_at.to_i)
    end

    it "parses a string timestamp" do
      assert_equal Word.last.created_at.to_time.change(usec: 0), KanjiController.new.send(:date_or_time_from, Word.last.created_at.to_s)
    end

    it "raises on invalid date or time" do
      assert_raises KanjiController::InvalidDateOrTime, "space_cats" do
        KanjiController.new.send(:date_or_time_from, "space_cats")
      end
    end
  end
end
