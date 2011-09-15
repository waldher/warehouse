class RealEstate < ActiveRecord::Base
  belongs_to :realtor
  belongs_to :customer
  has_many :real_estate_images

  accepts_nested_attributes_for :real_estate_images
end
