class ListingImage < ActiveRecord::Base
  belongs_to :listing

  has_attached_file :image, 
    :styles => { :thumbnail => "300x400>" },
    :storage => :s3, 
    :s3_credentials => "#{Rails.root}/config/s3.yml", 
    :path => ":id/:style/:filename"
end
