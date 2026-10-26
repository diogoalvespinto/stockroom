class CreateStockMovements < ActiveRecord::Migration[8.1]
  def change
    create_enum :stock_movement_kind, %w[receipt issue transfer_out transfer_in adjustment]

    create_table :stock_movements do |t|
      t.references :lot, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.enum :kind, enum_type: :stock_movement_kind, null: false
      t.integer :quantity, null: false
      t.text :reason
      t.datetime :created_at, null: false
    end
    add_index :stock_movements, [ :warehouse_id, :lot_id ]

    add_check_constraint :stock_movements, "quantity <> 0", name: "stock_movements_quantity_not_zero"
    add_check_constraint :stock_movements, <<~SQL.squish, name: "stock_movements_quantity_sign_matches_kind"
      (kind IN ('receipt', 'transfer_in') AND quantity > 0)
      OR (kind IN ('issue', 'transfer_out') AND quantity < 0)
      OR kind = 'adjustment'
    SQL
    add_check_constraint :stock_movements, <<~SQL.squish, name: "stock_movements_adjustment_has_reason"
      kind <> 'adjustment' OR btrim(coalesce(reason, '')) <> ''
    SQL

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE FUNCTION reject_stock_movement_changes() RETURNS trigger
          LANGUAGE plpgsql AS $$
          BEGIN
            RAISE EXCEPTION 'stock_movements is append-only: % is not allowed', TG_OP
              USING ERRCODE = 'restrict_violation';
          END;
          $$;

          CREATE TRIGGER stock_movements_append_only
          BEFORE UPDATE OR DELETE ON stock_movements
          FOR EACH ROW EXECUTE FUNCTION reject_stock_movement_changes();
        SQL
      end
      dir.down do
        execute <<~SQL
          DROP TRIGGER stock_movements_append_only ON stock_movements;
          DROP FUNCTION reject_stock_movement_changes();
        SQL
      end
    end
  end
end
