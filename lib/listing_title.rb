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

  WITHS = ["with", "w/", "has", "featuring", "features", "feat.", "incl.", "includes", "included", nil]

  #
  #Real Estate
  #
  INS = ["in", ","]

  LISTING_ADJECTIVES = ["beautiful", "gorgeous", "classy", "attractive", "lovely", "marvelous", "radiant", "wonderful", "comfortable", "excellent"]
  LOCATION_ADJECTIVES = ["alluring", "cozy", "quiet", "comfortable", "attractive", "lovely", "exquisite", "impressive", "classy", "wonderful", "fun", "convenient", "accessible"]
  ADJECTIVES = ["accessible", "adorable", "affluent", "alluring", "amazing", "angelic", "appealing", "ardent", "arousing", "artful", "astonishing", "astounding", "astute", "attractive", "beautiful", "bewitching", "blissful", "breathtaking", "brilliant", "canny", "captivating", "charming", "chic", "classic", "classy", "clever", "colorful", "comfortable", "contemplative", "convenient", "cozy", "dapper", "dashing", "dazzling", "delightful", "delighting", "desirable", "divine", "dreamy", "ebullient", "effusive", "elating", "elegant", "enchanted", "enchanting", "energetic", "enjoyable", "enticing", "euphoric", "excellent", "exciting", "exhilarating", "expansive", "exquisite", "extravagant", "exuberant", "exulting", "eye-catching", "fabulous", "fancy", "fantastic", "fashionable", "flashy", "foxy", "fresh", "fun", "glamorous", "glorious", "glowing", "gorgeous", "grand", "grandiose", "handsome", "impressive", "insightful", "intelligent", "intoxicating", "inviting", "jolly", "joyful", "joyous", "jubilant", "keen", "lavish", "lovely", "luscious", "lush", "luxurious", "magnetic", "magnificent", "majestic", "marvelous", "mighty", "modern", "opulent", "penetrating", "peppy", "perceptive", "perky", "phenomenal", "piercing", "pleasant", "plush", "pointed", "pretty", "profound", "quiet", "radiant", "refined", "remarkable", "ritzy", "sagacious", "sapient", "saucy", "savvy", "scintillating", "seductive", "sensational", "sensible", "sharky", "sharp", "showy", "shrewd", "slick", "smart", "sparkling", "spectacular", "splendid", "sporty", "sprightly", "striking", "stunning", "stupendous", "stylish", "sublime", "sumptuous", "superb", "superior", "swank", "tantalizing", "unreal", "vibrant", "vivacious", "wily", "wise", "wonderful", "wondrous"] 

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
      if o[:amenities] =~ /#{potential_amenity}/
        amenities_array << potential_amenity << (["tennis","basketball"].include?(potential_amenity) ? "court" : "")
      end
    end

    amenities = amenities_array * ", "

    transform = TRANSFORMS.sample

    return transform.call([ADJECTIVES.sample,
                      br,
                      type,
                      INS.sample,
                      
                      location,
                      amenities.empty? ? nil : WITHS.sample,
                      amenities.empty? ? nil : amenities].reject{|word| word.nil? }.join(" "))[0..69].gsub(/  /,' ')
  end
end
