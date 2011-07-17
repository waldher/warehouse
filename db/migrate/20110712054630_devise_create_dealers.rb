class DeviseCreateDealers < ActiveRecord::Migration
  def self.up
    create_table(:dealers) do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable

      # t.encryptable
      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable


      t.timestamps
    end

    add_index :dealers, :email,                :unique => true
    add_index :dealers, :reset_password_token, :unique => true
    # add_index :dealers, :confirmation_token,   :unique => true
    # add_index :dealers, :unlock_token,         :unique => true
    # add_index :dealers, :authentication_token, :unique => true
  end

  def self.down
    drop_table :dealers
  end
end
