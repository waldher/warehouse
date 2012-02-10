class Listing < ActiveRecord::Base
  belongs_to :customer

  has_many :listing_infos

  has_one :sublocation, :dependent => :destroy

  belongs_to :location
  belongs_to :sublocation

  has_many :listing_images, :dependent => :destroy, :order => "listing_images.threading"

  accepts_nested_attributes_for :listing_images, :allow_destroy => true

  attr_accessor :infos
  after_initialize :init_infos
  before_create :set_threading_number
  before_update :new_images_threading_number
  before_save :update_infos
  before_save :set_location_id

  def set_location_id
    sub = Sublocation.where(:id => self.sublocation).first
    loc = sub.location
    self.location_id = loc
  end

  def set_threading_number
    self.listing_images.each_with_index { |image, index|  image.threading = index + 1 }
  end

  def new_images_threading_number
    logger.debug "------------------------------"
    last_threading = self.listing_images.where(["threading != ?", 0]).last.threading rescue 0

    self.listing_images.detect { |image| 
     if image.new_record?
       image.threading = last_threading + 1
       last_threading += 1
     end
    }
    logger.debug self.listing_images.detect { |image| image.new_record? }.inspect
    logger.debug "------------------------------"
  end

  def title
    return infos[:ad_title]
  end

  def postable
    # Return false if no images?

    return true
  end

  after_create :create_infos

  def ad_image_urls
    return listing_images.where("image_updated_at is not null").collect{|li| li.image_url}
  end

  protected

  def init_infos
    @infos = {}

    for listing_info in self.listing_infos
      begin 
        @infos[listing_info.key.to_sym] = ActiveSupport::JSON.decode(listing_info.value)
      rescue 
        @infos[listing_info.key.to_sym] = listing_info.value
      end
    end
  end

  def create_infos
    for key, value in @infos
      if(value.kind_of?(Array) || value.kind_of?(Hash))
        ListingInfo.create(:listing_id => id, :key => key, :value => ActiveSupport::JSON.encode(value))
      else
        ListingInfo.create(:listing_id => id, :key => key, :value => value)
      end
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
          item_value = @infos[listing_info.key]
          if(item_value.kind_of?(Array) || item_value.kind_of?(Hash))
            listing_info.update_attributes(:value => ActiveSupport::JSON.encode(@infos[listing_info.key]))
          else
            listing_info.update_attributes(:value => @infos[listing_info.key])
          end
          updated << listing_info.key
        end
      end

      for key, value in @infos
        if !updated.to_s.include?(key.to_s)
          if(value.kind_of?(Array) || value.kind_of?(Hash))
            ListingInfo.create(:listing_id => id, :key => key, :value => ActiveSupport::JSON.encode(value))
          else
            ListingInfo.create(:listing_id => id, :key => key, :value => value)
          end
        end
      end
    end
  end
end
