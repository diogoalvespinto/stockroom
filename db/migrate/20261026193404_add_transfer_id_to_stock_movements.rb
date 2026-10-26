class AddTransferIdToStockMovements < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_movements, :transfer_id, :uuid
    add_index :stock_movements, :transfer_id, where: "transfer_id IS NOT NULL"
    add_check_constraint :stock_movements, <<~SQL.squish, name: "stock_movements_transfer_id_matches_kind"
      (kind IN ('transfer_out', 'transfer_in')) = (transfer_id IS NOT NULL)
    SQL
  end
end
