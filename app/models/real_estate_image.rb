class RealEstateImage < ActiveRecord::Base
  belongs_to :real_estate

  has_attached_file :image, :storage => :s3, :s3_credentials => "#{Rails.root}/config/s3.yml", :path => ":id/:filename"
end
