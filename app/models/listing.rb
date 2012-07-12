class Listing < ActiveRecord::Base
  belongs_to :customer

  has_many :listing_infos

  has_one :sublocation, :dependent => :destroy

  belongs_to :location
  belongs_to :sublocation

  has_many :listing_images, :dependent => :destroy, :order => "listing_images.threading"

  accepts_nested_attributes_for :listing_images, :allow_destroy => true
  validates_associated :listing_infos

  attr_accessor :infos
  after_initialize :init_infos
  before_create :set_threading_number
  before_update :new_images_threading_number
  before_save :update_infos
  before_save :set_location_id

  def set_location_id
    if sublocation
      self.location_id = sublocation.location_id
    end
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
    return infos["ad_title"].kind_of?(String) ? [infos["ad_title"]] : infos["ad_title"]
  end

  def active
    return (manual_enabled or (manual_enabled.nil? and foreign_active))
  end

  def postable
    # Return false if no images?

    return true
  end

  after_create :create_infos

  def ad_image_urls
    return listing_images.where("image_updated_at is not null").collect{|li| li.image_url}
  end

  def ad_autokeywords
    if infos.has_key?("ad_description")
      return CraigslistKeyword.filter(Word.synonyms(infos["ad_description"].split(/[ .,&()]+/)))
    end

    return []
  end

  protected

  def init_infos
    @infos = {}

    for listing_info in self.listing_infos
      begin
        @infos[listing_info.key] = JSON.parse(listing_info.value)
      rescue
        @infos[listing_info.key] = listing_info.value
      end
    end
  end

  def create_infos
    for key, value in @infos
      if(value.kind_of?(Array) || value.kind_of?(Hash))
        li=ListingInfo.create(:listing_id => id, :key => key, :value => value.to_json)
      else
        li=ListingInfo.create(:listing_id => id, :key => key, :value => value)
      end
      puts li.errors if li.errors and !li.errors.empty?
    end
  end

  def validate_listing_info_title
    if @infos["ad_title"].nil? or @infos["ad_title"].empty?
      errors[:title] = @infos["ad_title"]
      errors[:title_class] = @infos["ad_title"].class
      errors[:base] << "Must have at least one title!"
      return  true 
    else
      if @infos["ad_title"].kind_of?(String)
        if @infos["ad_title"].length > 70
          errors[:title] = @infos["ad_title"]
          errors[:title_length] = @infos["ad_title"].length
          errors[:title_class] = @infos["ad_title"].class
          errors[:base] << "More than 70 characters are not allowed"
          return true
        end
      else
        for title in @infos["ad_title"]
          if title.length > 70
            errors[:title] = title
            errors[:title_length] = title.length
            errors[:title_class] = @infos["ad_title"].class
            errors[:base] << "More than 70 characters are not allowed"
            return true
          end
        end
      end
    end
    return false
  end

  def update_infos
    return false if validate_listing_info_title
    #puts "Listing id: #{id}"
    logger.error "Infos: #{@infos}"
    #puts "Updated Infos Hash: #{@infos}"
    if id
      updated = []
      for listing_info in self.listing_infos
        #If the old info is not in the new info hash, delete.
        if !@infos.include?(listing_info.key)
          listing_info.delete
        #Update the old info
        else
          item_value = @infos[listing_info.key]
          if(item_value.kind_of?(Array) || item_value.kind_of?(Hash))
            listing_info.update_attribute(:value, item_value.to_json)
          else
            listing_info.update_attribute(:value, item_value)
          end
          #puts "Should be adding info #{listing_info.key.ljust(21,' ')} #{item_value.class} #{item_value}  #{listing_info.errors.to_s}"
          updated << listing_info.key
        end
      end

      #puts ""
      #puts updated.to_s
      #Create a new info
      for key, value in @infos
        #puts key 
        if !updated.to_s.include?(key.to_s)
          if(value.kind_of?(Array) || value.kind_of?(Hash))
            li=ListingInfo.create(:listing_id => id, :key => key, :value => value.to_json)
          else
            li=ListingInfo.create(:listing_id => id, :key => key, :value => value)
          end
          puts li.errors if li.errors and !li.errors.empty?
        end
      end
    end
  end
end
