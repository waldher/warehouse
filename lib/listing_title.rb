class ListingTitle
  UPCASE = Proc.new do |str|
      str.upcase
    end
  TITLECASE = Proc.new do |str|
      str.titlecase
    end
  DOWNCASE = Proc.new do |str|
      str.downcase
    end

  TRANSFORMS = [UPCASE, TITLECASE, DOWNCASE]

  WITHS = ["with", "w/", "has", "incl", nil]

  #
  #Real Estate
  #
  INS = ["in", nil]

  LISTING_ADJECTIVES = ["beautiful", "gorgeous", "classy", "attractive", "lovely", "marvelous", "radiant", "wonderful", "attractive", "comfortable"]
  LOCATION_ADJECTIVES = ["alluring", "cozy", "quiet", "comfortable", "attractive", "lovely", "exquisite", "impressive", "classy", "wonderful", "fun", "convenient", "accessible"]
  LOCATION_NOUNS = ["locale", "area", "community", "neighborhood", "location"]

  AMENITIES = ["balcony", "pool", "gym", "hot tub", "tennis", "basketball"]
  
  def self.generate(params={})
    o = { :bedrooms => 0,
          :type => nil,
          :location => nil,
          :amenities => ""}.merge(params)

    br = o[:bedrooms] == 0 ? nil : "#{o[:bedrooms]}br"
    type = (o[:type] or "unit")
    location = (o[:location] or LOCATION_NOUNS.sample)
    amenities_array = []

    for potential_amenity in AMENITIES
      if o[:amenities] =~ /#{potential_amenity}/i
        amenities_array << potential_amenity
      end
    end

    amenities = amenities_array * " "

    transform = TRANSFORMS.sample

    return transform.call([LISTING_ADJECTIVES.sample,
                      br,
                      type,
                      INS.sample,
                      LOCATION_ADJECTIVES.sample,
                      location,
                      amenities.empty? ? nil : WITHS.sample,
                      amenities.empty? ? nil : amenities].reject{|word| word.nil? }.join(" "))[0..69]
  end
end
