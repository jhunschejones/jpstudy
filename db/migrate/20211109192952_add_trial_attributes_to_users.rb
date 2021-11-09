class AddTrialAttributesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :trial_starts_at, :datetime
    add_column :users, :trail_ends_at, :datetime
  end
end
