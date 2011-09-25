class RemoveDealersRealtors < ActiveRecord::Migration
  def self.up
    drop_table :realtors
    drop_table :dealers
    drop_table :dealer_infos
  end

  def self.down
  end
end
