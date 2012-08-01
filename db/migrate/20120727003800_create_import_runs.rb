class CreateImportRuns < ActiveRecord::Migration
  def self.up
    create_table :import_runs do |t|
      t.text :input, :nil => false
      t.text :output
      t.boolean :finished, :nil => false, :default => false
      t.string :source, :nil => false

      t.timestamps
    end
  end

  def self.down
    drop_table :import_runs
  end
end
