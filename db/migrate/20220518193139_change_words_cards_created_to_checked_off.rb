class ChangeWordsCardsCreatedToCheckedOff < ActiveRecord::Migration[7.0]
  def change
    rename_column :words, :cards_created_at, :checked_off_at
    rename_column :words, :cards_created, :checked_off
  end
end
