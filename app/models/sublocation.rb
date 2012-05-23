class Sublocation < ActiveRecord::Base
  belongs_to :location
  has_many :customers
  validates_presence_of :name

  before_validation :caps

  def caps
    self.name.capitalize! if name
  end
end
