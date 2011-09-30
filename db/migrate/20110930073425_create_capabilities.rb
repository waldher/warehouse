class CreateCapabilities < ActiveRecord::Migration
  def self.up
    create_table :capabilities do |t|
      t.string :name, :null => false

      t.timestamps
    end

    add_index :capabilities, :name, :unique => true

    create_table :capabilities_customers, :id => false do |t|
      t.integer :capability_id
      t.integer :customer_id
    end
  end

  def self.down
    drop_table :capabilities_customers
    drop_table :capabilities
  end
end
