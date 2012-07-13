class AddListingsCraigslistType < ActiveRecord::Migration
  def self.up
    add_column :listings, :craigslist_type, :string
  end

  def self.down
    remove_column :listings, :craigslist_type
  end
end
