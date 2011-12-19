class AddLocationSublocationsUrl < ActiveRecord::Migration
  def self.up
    add_column :locations, :url, :string
    add_column :sublocations, :url, :string

    add_index :locations, :name, :unique => true
    add_index :locations, :url, :unique => true
    add_index :sublocations, [:location_id, :name], :unique => true
    add_index :sublocations, [:location_id, :url], :unique => true

    change_column :locations, :name, :string, :null => false
    change_column :sublocations, :name, :string, :null => false
    change_column :locations, :url, :string, :null => false
    change_column :sublocations, :url, :string, :null => false
  end

  def self.down
    remove_column :locations, :url
    remove_column :sublocations, :url

    remove_index :locations, :name
    remove_index :sublocations, [:location_id, :name]
  end
end
