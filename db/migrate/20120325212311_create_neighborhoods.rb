class CreateNeighborhoods < ActiveRecord::Migration
  def self.up
    create_table :neighborhoods do |t|
      t.integer :sublocation_id, :null => false, :references => :sublocations
      t.string :name, :null => false
      t.integer :craigslist_id, :null => false

      t.timestamps
    end
    
    add_column :listings, :neighborhood_id, :integer, :null => true, :references => :neighborhoods
  end

  def self.down
    remove_column :listings, :neighborhood_id

    drop_table :neighborhoods
  end
end
