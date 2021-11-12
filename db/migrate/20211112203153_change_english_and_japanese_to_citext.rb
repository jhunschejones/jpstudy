class ChangeEnglishAndJapaneseToCitext < ActiveRecord::Migration[7.0]
  def up
    enable_extension "citext"
    change_column :words, :english, :citext
    change_column :words, :japanese, :citext
  end

  def down
    change_column :words, :english, :text
    change_column :words, :japanese, :text
    disable_extension "citext"
  end
end
