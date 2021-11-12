class AddWordsCountToUsers < ActiveRecord::Migration[7.0]
  def change
    # Based on https://blog.appsignal.com/2018/06/19/activerecords-counter-cache.html
    add_column :users, :words_count, :bigint
  end
end
