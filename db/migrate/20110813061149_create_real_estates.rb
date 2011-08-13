class CreateRealEstates < ActiveRecord::Migration
  def self.up
    create_table :real_estates do |t|
      t.integer :realtor_id, :null => false
      t.text :ad_title, :null => false
      t.text :ad_description
      t.integer :bedrooms
      t.integer :price
      t.boolean :cats, :null => false, :default => false
      t.boolean :dogs, :null => false, :default => false
      t.boolean :active, :null => false, :default => true

      t.timestamps
    end
    add_index :real_estates, :realtor_id
  end

  def self.down
    drop_table :real_estates
  end
end
