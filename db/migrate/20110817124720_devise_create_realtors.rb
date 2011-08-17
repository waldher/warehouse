class DeviseCreateRealtors < ActiveRecord::Migration
  def self.up
    create_table(:realtors) do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable

      # t.encryptable
      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable
      
      t.string :name, :null => false
      t.string :realtor_key, :null => false

      t.timestamps
    end

    add_index :realtors, :email,                :unique => true
    add_index :realtors, :reset_password_token, :unique => true
    # add_index :realtors, :confirmation_token,   :unique => true
    # add_index :realtors, :unlock_token,         :unique => true
    # add_index :realtors, :authentication_token, :unique => true

    add_index :realtors, :realtor_key, :unique => true
  end

  def self.down
    drop_table :realtors
  end
end
