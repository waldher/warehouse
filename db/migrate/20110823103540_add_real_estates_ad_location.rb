class AddRealEstatesAdLocation < ActiveRecord::Migration
  def self.up
    add_column :real_estates, :ad_location, :string
  end

  def self.down
    remove_column :real_estates, :ad_location
  end
end
