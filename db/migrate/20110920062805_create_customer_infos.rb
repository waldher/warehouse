class CreateCustomerInfos < ActiveRecord::Migration
  def self.up
    create_table :customer_infos do |t|
      t.integer :customer_id
      t.integer :version, :null => false, :default => 0
      t.string :key
      t.string :value
    end
    add_index(:customer_infos, :customer_id)
  end

  def self.down
    drop_table :customer_infos
  end
end
