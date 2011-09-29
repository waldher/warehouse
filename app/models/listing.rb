class Listing < ActiveRecord::Base
  belongs_to :customer

  has_many :listing_infos

  has_many :listing_images, :dependent => :destroy

  accepts_nested_attributes_for :listing_images, :allow_destroy => true

  attr_accessor :infos
  after_initialize :init_infos
  before_save :update_infos

  def title
    return infos[:ad_title]
  end

  def postable
    # Return false if no images?

    return true
  end

  after_create :create_infos

  def ad_image_urls
    return listing_images.collect{|li| li.image_url}
  end

  protected

  def init_infos
    @infos = {}

    for listing_info in self.listing_infos
      @infos[listing_info.key.to_sym] = listing_info.value
    end
  end

  def create_infos
    for key, value in @infos
      ListingInfo.create(:listing_id => id, :key => key, :value => value)
    end
  end

  def update_infos
    logger.error "Infos: #{infos}"
    if id
      updated = []
      for listing_info in self.listing_infos
        if !@infos.include?(listing_info.key)
          listing_info.delete
        else
          listing_info.update_attributes(:value => @infos[listing_info.key])
          updated << listing_info.key
        end
      end

      for key, value in @infos
        if !updated.include?(key)
          ListingInfo.create(:listing_id => id, :key => key, :value => value)
        end
      end
    end
  end
end
