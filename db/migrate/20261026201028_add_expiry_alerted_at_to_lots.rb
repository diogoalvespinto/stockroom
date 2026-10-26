class AddExpiryAlertedAtToLots < ActiveRecord::Migration[8.1]
  def change
    add_column :lots, :expiry_alerted_at, :datetime
  end
end
