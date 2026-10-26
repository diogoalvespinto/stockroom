class IncludeQuantityInStockBalanceIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :stock_movements, [ :warehouse_id, :lot_id ],
      include: :quantity, name: "index_stock_movements_for_balances", algorithm: :concurrently
    remove_index :stock_movements, [ :warehouse_id, :lot_id ],
      name: "index_stock_movements_on_warehouse_id_and_lot_id", algorithm: :concurrently
  end
end
