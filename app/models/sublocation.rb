class Sublocation < ActiveRecord::Base
  belongs_to :location
  has_many :customers

  after_initialize :caps

  def caps
    self.name.capitalize!
  end
end
