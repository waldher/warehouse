class AddListingImagesIndex < ActiveRecord::Migration
  def self.up
    add_index :listing_images, :listing_id
  end

  def self.down
  end
end
