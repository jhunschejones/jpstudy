class CreateKanji < ActiveRecord::Migration[7.0]
  def change
    create_table :kanji do |t|
      t.string :character, null: false
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :kanji, [:user_id, :character], unique: true
  end
end
