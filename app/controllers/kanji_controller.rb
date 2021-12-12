class KanjiController < ApplicationController
  before_action :secure_behind_subscription

  def next
  end

  def import
  end

  def upload
  end

  def export
  end

  def download
  end

  private

  def kanji_params
    params.require(:kanji).permit(:character, :status, :user_id)
  end
end
