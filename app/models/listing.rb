class Listing < ActiveRecord::Base
  belongs_to :customer

  has_many :listing_infos

  attr_accessor :infos
  after_initialize :init_infos
  before_save :update_infos

  def title
    return infos[:ad_title]
  end

  protected
  
  def init_infos
    @infos = {}

    for listing_info in self.listing_infos
      @infos[listing_info.key.to_sym] = listing_info.value
    end
  end

  def update_infos
    logger.error "Infos: #{infos}"
    updated = []
    for listing_info in self.listing_infos
      if !@infos.include?(listing_info.key)
        listing_info.delete
      else
        listing_info.update_attribute(:value => @infos[listing_info.key])
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