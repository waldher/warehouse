class ListingImage < ActiveRecord::Base
  belongs_to :listing

  has_attached_file :image
end
