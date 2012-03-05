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

  LISTING_ADJECTIVES = ["beautiful", "gorgeous", "classy", "attractive", "lovely", "marvelous", "radiant", "wonderful", "comfortable", "excellent", "dazzling", "bewitching", "appealing", "delightful", "divine", "angelic", "enticing", "elegant", "handsome", "grand", "magnificent", "marvelous", "pretty", "radiant", "refined", "splendid", "stunning", "sublime", "superb", "wonderful", "captivating", "charming", "enchanting", "magnetic", "classic", "chic", "exquisite", "fancy", "fassionable", "luxurious", "majestic", "refined", "sumptuous", "superior", "stylish", "adorable", "charming", "glamorous", "georgeous", "inviting", "lovely", "pleasant", "seductive", "stunning", "tantalizing", "enticing", "brilliant", "colorful", "dreamy", "elegant", "enjoyable", "exquisite", "glorious", "impressive", "lavish", "lovely", "opulent", "dashing", "extravagant", "grandiose", "spectacular", "sporty", "swank", "deluxe", "lavish", "luscious", "plush", "luscious", "lush", "ritzy", "fantastic", "flashy", "showy", "dashing", "extravagant", "spectacular", "sporty", "amazing", "breathtaking", "astounding", "astonishing", "eye-catching", "fabulous", "grand", "magnificent", "marvelous", "remarkable", "sensational", "splendid", "striking", "stunning", "stupendous", "wonderous", "fantastic", "mighty", "phenominal", "spectacular", "unreal", "wondorous", "lavish" , "showy", "affluent", "affluent", "enticing", "exuberant", "elating", "exhilirating", "sparkling", "ardent", "desireable", "glowing", "vivacious", "scintillating", "sprightly", "vibrant", "ebullient", "chipper", "elating", "exuberant", "enchanting", "enchanted", "euphoric", "blissful", "arousing", "delighting", "exciting", "exhilarating", "intoxicating", "joyful", "joyous", "jubilant", "effusive", "expansive", "extravagant", "lavish", "ebullient", "blissful", "delighting", "exulting", "exciting", "enchanted", "enchanting", "intoxicating", "jubilant", "sprightly", "dapper", "dashing", "energetic", "jolly", "peppy", "perky", "saucy", "smart", "lucious", "lush", "ritzy", "sumptuous", "brilliant", "fresh", "pointed", "sharp", "shrewd", "keen", "wise", "artful", "modern", "penetrating", "perceptive", "piercing", "prudent", "profound", "savvy", "sensible", "sharky", "sharp" , "slick", "smarth", "wily", "wise", "sagacious", "astute", "canny", "clever", "insightful", "intelligent", "prudent", "rational", "sapient", "contemplative", "discerning", "discriminating", "foxy", "sensible"]
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
