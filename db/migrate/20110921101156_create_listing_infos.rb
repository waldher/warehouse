class CreateListingInfos < ActiveRecord::Migration
  def self.up
    create_table :listing_infos do |t|
      t.integer :listing_id, :references => :listing, :null => false
      t.string :key, :null => false
      t.string :value, :null => false

      t.timestamps
    end

    add_index :listing_infos, [:listing_id, :key], :unique => true
  end

  def self.down
    drop_table :listing_infos
  end
end
