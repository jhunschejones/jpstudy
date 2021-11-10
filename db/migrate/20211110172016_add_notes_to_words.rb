class AddNotesToWords < ActiveRecord::Migration[7.0]
  def change
    add_column :words, :note, :text
  end
end
