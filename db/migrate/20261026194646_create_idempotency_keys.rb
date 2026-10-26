class CreateIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :idempotency_keys do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :key, null: false
      t.string :request_digest, null: false
      t.integer :response_status
      t.text :response_body
      t.datetime :created_at, null: false
    end
    add_index :idempotency_keys, [ :user_id, :key ], unique: true
    add_index :idempotency_keys, :created_at
  end
end
