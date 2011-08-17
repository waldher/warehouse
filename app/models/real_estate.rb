class RealEstate < ActiveRecord::Base
  belongs_to :realtor
  has_many :real_estate_images

  accepts_nested_attributes_for :real_estate_images
end
