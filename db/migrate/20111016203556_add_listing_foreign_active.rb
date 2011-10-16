class AddListingForeignActive < ActiveRecord::Migration
  def self.up
    add_column :listings, :foreign_active, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :listings, :foreign_active
  end
end
