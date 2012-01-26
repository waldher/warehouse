class Sublocation < ActiveRecord::Base
  belongs_to :location

  after_initialize :caps

  def caps
    self.name.capitalize!
  end
end
