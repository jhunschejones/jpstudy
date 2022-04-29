require "application_controller_test_case"

class KanjiControllerTest < ApplicationControllerTestCase
  describe "#index" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      assert_no_difference "Memo.count" do
        get memos_path(users(:elemouse))
      end
      assert_redirected_to user_path(users(:elemouse))
    end

    it "returns the memos page" do
      login(users(:carl))
      get memos_path(users(:carl))
      assert_response :success
      assert_select ".page-title", "Study memos"
    end

    it "creates a new memo for the user if they don't have one yet" do
      login(users(:carl))
      assert_difference "Memo.count", 1 do
        get memos_path(users(:carl))
      end
    end

    it "does not create a memo if the user already has one" do
      Memo.create!(user: users(:carl))
      login(users(:carl))
      assert_no_difference "Memo.count" do
        get memos_path(users(:carl))
      end
    end
  end

  describe "#update" do
    it "requires subscription or trial to access" do
      login(users(:elemouse))
      @memo = Memo.create!(user: users(:elemouse))
      patch memo_path(users(:elemouse), @memo), params: { memo: { content: "My new study notes" } }
      assert_redirected_to user_path(users(:elemouse))
    end

    it "updates the user's memo" do
      login(users(:carl))
      @memo = Memo.create!(user: users(:carl))
      assert_changes "@memo.reload.content" do
        patch memo_path(users(:carl), @memo), params: { memo: { content: "My new study notes" } }
      end
    end

    it "redirects to the memos page and shows the updated memo" do
      login(users(:carl))
      @memo = Memo.create!(user: users(:carl))
      patch memo_path(users(:carl), @memo), params: { memo: { content: "My new study notes" } }
      assert_redirected_to memos_path(users(:carl))
      follow_redirect!
      assert_match /My new study notes/, response.body
    end
  end
end
