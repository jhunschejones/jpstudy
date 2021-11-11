class AddAddedToListAtToWords < ActiveRecord::Migration[7.0]
  def change
    add_column :words, :added_to_list_at, :datetime
  end
end
