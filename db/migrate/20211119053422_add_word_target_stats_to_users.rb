class AddWordTargetStatsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :next_word_goal, :bigint
    add_column :users, :daily_word_target, :bigint
  end
end
