class DropDirectoryRealEstateTables < ActiveRecord::Migration
  def self.up
    drop_table :directory_files
    drop_table :directories
    drop_table :log_files

    drop_table :real_estate_images
    drop_table :real_estates
  end

  def self.down
  end
end
