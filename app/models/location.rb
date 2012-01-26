class Location < ActiveRecord::Base
  has_many :sublocations, :dependent => :destroy

  after_initialize :caps

  def caps
    self.name.capitalize!
  end
end
