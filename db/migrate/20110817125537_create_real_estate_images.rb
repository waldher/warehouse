class CreateRealEstateImages < ActiveRecord::Migration
  def self.up
    create_table :real_estate_images do |t|
      t.integer :real_estate_id, :references => :real_estate, :null => false

      t.string :image_file_name
      t.string :image_content_type
      t.integer :image_file_size
      t.datetime :image_updated_at

      t.timestamps
    end
  end

  def self.down
    drop_table :real_estate_images
  end
end
