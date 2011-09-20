class AddCustomersSetupNonce < ActiveRecord::Migration
  def self.up
    add_column :customers, :setup_nonce, :string

    add_index :customers, :setup_nonce, :unique => true
  end

  def self.down
    remove_column :customers, :setup_nonce
  end
end
