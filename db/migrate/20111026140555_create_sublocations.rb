class CreateSublocations < ActiveRecord::Migration
  def self.up
    create_table :sublocations do |t|
      t.string :name
      t.references :location
    end
    add_index :sublocations, :location_id
  end

  def self.down
    drop_table :sublocations
  end
end
