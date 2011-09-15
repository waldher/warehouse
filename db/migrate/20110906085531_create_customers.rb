class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.string :email_address
      t.string :hashed_password
      t.string :salt
      t.string :key
      t.integer :role_id

      t.timestamps
    end
    add_index(:customers, :role_id)
    add_index(:customers, :key)
  end

  def self.down
    drop_table :customers
  end
end
