class AddRealEstatesAdKeywords < ActiveRecord::Migration
  def self.up
    add_column :real_estates, :ad_keywords, :string, :null => false, :default => ""
  end

  def self.down
    remove_column :real_estates, :ad_keywords
  end
end
