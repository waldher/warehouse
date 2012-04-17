class AddListingsCustomerIdIndex < ActiveRecord::Migration
  def self.up
    add_index :listings, :customer_id
  end

  def self.down
    remove_index :listings, :customer_id
  end
end
