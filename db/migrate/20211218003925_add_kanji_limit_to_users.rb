class AddKanjiLimitToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :kanji_limit, :bigint
  end
end
