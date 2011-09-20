class ReplaceRoleWithCustomerCraigslistType < ActiveRecord::Migration
  def self.up
    drop_table :roles

    add_column :customers, :craigslist_type, :string, :null => false, :default => 'apa'
  end

  def self.down
    remove_column :customers, :craigslist_type

    create_table :roles do |t|
      t.string :name
    end
    Role.create!(:name => "Dealer")
    Role.create!(:name => "Realtor")
  end
end
