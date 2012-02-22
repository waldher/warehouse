class ListingInfo < ActiveRecord::Base
  belongs_to :listing

  def value
    if read_attribute(:value).kind_of?(String)
       read_attribute(:value).force_encoding("UTF-8")
    end
  end
end
