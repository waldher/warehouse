class AddCapabilityAgents < ActiveRecord::Migration
  def self.up
    Capability.create(:name => "agents")
  end

  def self.down
    Capability.find_by_name("agents").destroy
  end
end
