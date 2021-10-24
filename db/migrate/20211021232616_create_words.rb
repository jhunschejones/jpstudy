class CreateWords < ActiveRecord::Migration[7.0]
  def change
    create_table :words do |t|
      t.text :japanese, null: false
      t.text :english, null: false
      t.text :source_name
      t.text :source_reference
      t.datetime :cards_created_on
      t.timestamps
    end
  end
end
