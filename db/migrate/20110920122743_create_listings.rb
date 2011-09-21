class CreateListings < ActiveRecord::Migration
  def self.up
    create_table :listings do |t|
      t.integer :customer_id, :references => :customer, :null => false
      t.boolean :active, :null => false, :default => true
      t.integer :price
      t.text :keywords, :null => false, :default => ''

      t.timestamps
    end
  end

  def self.down
    drop_table :listings
  end
end
