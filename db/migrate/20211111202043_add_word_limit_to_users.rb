class AddWordLimitToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :word_limit, :bigint
  end
end
