class AddListingsForeignId < ActiveRecord::Migration
  def self.up
    add_column :listings, :foreign_id, :string

    for listing in Listing.all
      if listing.infos[:ad_foreign_id]
        listing.update_attribute(:foreign_id, listing.infos[:ad_foreign_id])
      end
    end
  end

  def self.down
    remove_column :listings, :foreign_id
  end
end
