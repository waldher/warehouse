class ListingImage < ActiveRecord::Base
  belongs_to :listing

  has_attached_file :image, 
    :storage => :s3, 
    :s3_credentials => "#{Rails.root}/config/s3.yml", 
    :path => ":id/:style/:filename",
    :s3_permissions => :public_read

  after_create :set_complete_image_url

  def set_complete_image_url
    update_attribute(:complete_image_url, image_url)
  end

  def image_url
    self.image.url
  end
end
