class AddThreadingToListingImages < ActiveRecord::Migration
  def self.up
    add_column :listing_images, :threading, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :listing_images, :threading
  end
end
