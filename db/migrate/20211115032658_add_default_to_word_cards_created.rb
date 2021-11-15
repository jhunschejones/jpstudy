class AddDefaultToWordCardsCreated < ActiveRecord::Migration[7.0]
  def change
    change_column_default :words, :cards_created, from: nil, to: false
  end
end
