class AddCardsCreatedAtToWords < ActiveRecord::Migration[7.0]
  def change
    add_column :words, :cards_created_at, :datetime
  end
end
