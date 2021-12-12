class AddKanjiCounterCacheToUser < ActiveRecord::Migration[7.0]
  def change
    # Based on https://blog.appsignal.com/2018/06/19/activerecords-counter-cache.html
    add_column :users, :kanjis_count, :bigint
  end
end
