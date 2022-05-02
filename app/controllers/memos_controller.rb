class MemosController < ApplicationController
  READ_ACTIONS = [:index]

  before_action :secure_behind_subscription
  before_action ->{ protect_user_scoped_read_actions_for(:memo) }, only: READ_ACTIONS
  before_action :protect_user_scoped_modify_actions, except: READ_ACTIONS
  before_action :set_memo

  def index
  end

  def update
    @memo.update!(memo_params)
    respond_to do |format|
      format.html do
        flash[:hide_in_ms] = 1800
        flash[:success] = "Memos saved 🎉"
        redirect_to memos_path(@resource_owner)
      end
      format.json { head :ok }
    end
  end

  private

  def memo_params
    params.require(:memo).permit(:content)
  end

  def set_memo
    # For now, each user only has one memo record
    @memo = @resource_owner.memos.with_rich_text_content.first || Memo.create!(user: @resource_owner)
  end
end
