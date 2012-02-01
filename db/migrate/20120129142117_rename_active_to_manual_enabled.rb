class RenameActiveToManualEnabled < ActiveRecord::Migration
  def self.up
    rename_column :listings, :active, :manual_enabled
    change_column :listings, :manual_enabled, :boolean, :null => true
    # Iterate over all listings to get listing_infos
    Listing.includes(:listing_infos).where(:listing_infos => {:key => 'ad_foreign_id'}).each do |listing|
      listing.listing_infos.where(:key => 'ad_foreign_id').each do |info|
        info.destroy
      end
    end
  end

  def self.down
    change_column :listings, :manual_enabled, :boolean, :null => false
    rename_column :listings, :manual_enabled, :active
  end
end
