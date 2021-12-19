class AddAddedToListAtToKanji < ActiveRecord::Migration[7.0]
  def change
    add_column :kanji, :added_to_list_at, :datetime
  end
end
