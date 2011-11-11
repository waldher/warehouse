class ListingInfo < ActiveRecord::Base
  belongs_to :listing

  def value
    read_attribute(:value).force_encoding("UTF-8")
  end
end
