class Location < ActiveRecord::Base
  has_many :sublocations, :dependent => :destroy
  has_many :customers

  after_initialize :caps

  def caps
    self.name.capitalize!
  end
end
