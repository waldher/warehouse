class Location < ActiveRecord::Base
  has_many :sublocations, :dependent => :destroy
end
