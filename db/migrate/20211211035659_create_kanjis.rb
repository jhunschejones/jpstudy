class CreateKanjis < ActiveRecord::Migration[7.0]
  def change
    create_table :kanjis do |t|
      t.string :character, null: false
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :kanjis, [:user_id, :character], unique: true
  end
end
