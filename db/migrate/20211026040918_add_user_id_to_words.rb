class AddUserIdToWords < ActiveRecord::Migration[7.0]
  def change
    add_reference :words, :user, foreign_key: true
  end
end
