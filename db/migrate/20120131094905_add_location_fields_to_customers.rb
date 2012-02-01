class AddLocationFieldsToCustomers < ActiveRecord::Migration
  def self.up
    add_column :customers, :location_id, :integer
    add_column :customers, :sublocation_id, :integer
  end

  def self.down
    remove_column :customers, :sublocation_id
    remove_column :customers, :location_id
  end
end
