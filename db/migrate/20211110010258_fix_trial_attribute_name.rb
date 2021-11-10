class FixTrialAttributeName < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :trail_ends_at, :trial_ends_at
  end
end
