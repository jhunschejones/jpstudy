class AddKanjiTargetStatsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :next_kanji_goal, :bigint
    add_column :users, :daily_kanji_target, :bigint
  end
end
