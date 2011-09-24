class CreateListingImages < ActiveRecord::Migration
  def self.up
    create_table :listing_images do |t|
      t.references :listing

      t.timestamps
    end
  end

  def self.down
    drop_table :listing_images
  end
end
