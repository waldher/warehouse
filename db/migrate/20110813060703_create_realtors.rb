class CreateRealtors < ActiveRecord::Migration
  def self.up
    create_table :realtors do |t|
      t.string :name, :null => false
      t.string :email, :null => false, :unique => true
      t.integer :realtor_key, :null => false, :unique => true
      t.string :contact_name
      t.text :contact_address
      t.string :contact_phone

      t.timestamps
    end
  end

  def self.down
    drop_table :realtors
  end
end
