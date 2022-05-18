class RenameCheckedOffToChecked < ActiveRecord::Migration[7.0]
  def change
    rename_column :words, :checked_off_at, :checked_at
    rename_column :words, :checked_off, :checked
  end
end
