class AddStarredToWords < ActiveRecord::Migration[7.0]
  def change
    add_column :words, :starred, :boolean, default: false
  end
end
