class ChangeListingInfosValueText < ActiveRecord::Migration
  def self.up
    change_column :listing_infos, :value, :text, :null => false
  end

  def self.down
    change_column :listing_infos, :value, :string, :null => false
  end
end
