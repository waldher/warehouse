class AddCompleteImageUrlToListingImages < ActiveRecord::Migration
  def self.up
    add_column :listing_images, :complete_image_url, :string
    ListingImage.all.each do |image|
      image.update_attribute(:complete_image_url, image.image_url)
    end
  end

  def self.down
    remove_column :listing_images, :complete_image_url
  end
end
