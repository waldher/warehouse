class RemoveListingPriceKeywords < ActiveRecord::Migration
  def self.up
    remove_column :listings, :price
    remove_column :listings, :keywords
  end

  def self.down
    add_column :listings, :price, :integer
    add_column :listings, :keywords, :text, :null => false, :default => ''
  end
end
