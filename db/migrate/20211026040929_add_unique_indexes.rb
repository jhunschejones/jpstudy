class AddUniqueIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :words, [:user_id, :japanese, :english], unique: true
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
  end
end
