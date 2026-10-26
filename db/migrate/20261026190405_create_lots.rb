class CreateLots < ActiveRecord::Migration[8.1]
  def change
    create_table :lots do |t|
      t.references :item, null: false, foreign_key: true, index: false
      t.string :lot_number, null: false
      t.date :expiry_date

      t.timestamps
    end
    add_index :lots, [ :item_id, :lot_number ], unique: true
  end
end
