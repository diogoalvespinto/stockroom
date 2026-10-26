class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.string :unit_of_measure, null: false
      t.integer :reorder_level, null: false, default: 0

      t.timestamps
    end
    add_index :items, :sku, unique: true
    add_check_constraint :items, "reorder_level >= 0", name: "items_reorder_level_not_negative"
  end
end
