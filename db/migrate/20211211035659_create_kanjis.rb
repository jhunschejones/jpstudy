class CreateKanjis < ActiveRecord::Migration[7.0]
  def change
    create_table :kanjis do |t|
      t.string :character, null: false
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :kanjis, [:user_id, :character], unique: true

    # TODO: move this to its own migration
    # Based on https://blog.appsignal.com/2018/06/19/activerecords-counter-cache.html
    add_column :users, :kanjis_count, :bigint
  end
end
