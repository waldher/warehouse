class ChangeListingsManualEnabledDefault < ActiveRecord::Migration
  def self.up
    change_column_default :listings, :manual_enabled, nil
  end

  def self.down
    change_column_default :listings, :manual_enabled, true
  end
end
