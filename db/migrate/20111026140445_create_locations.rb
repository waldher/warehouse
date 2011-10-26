class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :name, :null => false, :default => ""
      t.boolean :enabled, :null => false, :default => false
    end
  end

  def self.down
    drop_table :locations
  end
end
