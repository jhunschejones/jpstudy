class AddResetAndVerificationFieldsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :verified, :boolean, default: false
    add_column :users, :verified_at, :datetime
    add_column :users, :verification_digest, :string
    add_column :users, :unverified_email, :string

    add_column :users, :reset_sent_at, :datetime
    add_column :users, :reset_digest, :string
  end
end
