class Realtor < ActiveRecord::Base
  has_many :real_estates
  has_many :real_estate_images, :as => :imageable
end
