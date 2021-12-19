require "application_controller_test_case"

class KanjiControllerTest < ApplicationControllerTestCase
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
