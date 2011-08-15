class RealEstate < ActiveRecord::Base
  belongs_to :realtor, :foreign_key => :realtor_id
   has_many :real_estate_images, :as => :imageable
end
