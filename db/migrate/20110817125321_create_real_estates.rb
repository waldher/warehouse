class CreateRealEstates < ActiveRecord::Migration
  def self.up
    create_table :real_estates do |t|
      t.integer :realtor_id, :references => :realtor, :null => false
      t.text :ad_title, :null => false
      t.text :ad_description, :null => false
      t.integer :bedrooms
      t.integer :price
      t.boolean :cats, :null => false, :default => false
      t.boolean :dogs, :null => false, :default => false
      t.boolean :active, :null => false, :default => true

      t.timestamps
    end
  end

  def self.down
    drop_table :real_estates
  end
end
