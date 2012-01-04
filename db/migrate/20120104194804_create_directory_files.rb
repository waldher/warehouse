class CreateDirectoryFiles < ActiveRecord::Migration
  def self.up
    create_table :directory_files, :force => true do |t|
      t.string :ip_address
      t.references :directory
      t.string :filename
      t.boolean :click
      t.text :raw
      t.datetime :requested_at

      t.timestamps
    end
    add_index(:directory_files, :directory_id)
    add_index(:directory_files, :click)
    add_index(:directory_files, :requested_at)
  end

  def self.down
    drop_table :directory_files
  end
end
