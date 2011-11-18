class AddListingsLocationSublocation < ActiveRecord::Migration
  def self.up
    add_column :listings, :location_id, :integer, :references => :location
    add_column :listings, :sublocation_id, :integer, :references => :sublocation
  end

  def self.down
    remove_column :listings, :location_id
    remove_column :listings, :sublocation_id
  end
end
