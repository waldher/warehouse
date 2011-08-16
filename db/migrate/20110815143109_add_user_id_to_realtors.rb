class AddUserIdToRealtors < ActiveRecord::Migration
  def self.up
    add_column :realtors, :user_id, :integer
  end

  def self.down
    remove_column :realtors, :user_id
  end
end
