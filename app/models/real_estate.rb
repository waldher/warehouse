class RealEstate < ActiveRecord::Base
  belongs_to :realtor
  has_many :real_estate_images

  accepts_nested_attributes_for :real_estate_images

  def image_urls
    real_estate_images.collect{|rei| rei.image.url }
  end
end
