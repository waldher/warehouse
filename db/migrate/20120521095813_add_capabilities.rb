class AddCapabilities < ActiveRecord::Migration
  def self.up
    add_column :capabilities, :bathrooms, :integer
    add_column :capabilities, :style, :string
    add_column :capabilities, :square_footage, :float
    # The type of this column depends on the number of agents that each real estate has and if
    # there is any register os agents, so, the field may be an integer, but I will let it be a
    # string.
    add_column :capabilities, :agents, :string
    add_column :capabilities, :construction, :string
  end

  def self.down
    remove_column :capabilities, :bathrooms
    remove_column :capabilities, :style
    remove_column :capabilities, :square_footage
    remove_column :capabilities, :agents
    remove_column :capabilities, :construction
  end
end
