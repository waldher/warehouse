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

  WITHS = ["with", "w/", "has", "features", "feat.", "incl.", "includes"]

  POST = ["included", "available", "featured"]

  INS = ["in", ","]

  LISTING_ADJECTIVES = ["beautiful", "gorgeous", "classy", "attractive", "lovely", "marvelous", "radiant", "wonderful", "comfortable", "excellent", "dazzling", "bewitching"]
  LOCATION_ADJECTIVES = ["alluring", "cozy", "quiet", "comfortable", "attractive", "lovely", "exquisite", "impressive", "classy", "wonderful", "fun", "convenient", "accessible"]
  
  ADJECTIVES = ["accessible", "adorable", "alluring", "amazing", "angelic", "appealing", "ardent", "arousing", "artful", "astonishing", "attractive", "beautiful", "bewitching", "blissful", "breathtaking", "canny", "captivating", "charming", "chic", "classic", "classy", "colorful", "comfortable", "convenient", "cozy", "dapper", "dashing", "dazzling", "delightful", "delighting", "desirable", "divine", "dreamy", "ebullient", "effusive", "elating", "elegant", "enchanted", "enchanting", "energetic", "enjoyable", "enticing", "euphoric", "excellent", "exciting", "exhilarating", "expansive", "exquisite", "extravagant", "exuberant", "exulting", "eye-catching", "fabulous", "fancy", "fantastic", "fashionable", "flashy", "foxy", "fresh", "fun", "glamorous", "glorious", "glowing", "gorgeous", "grand", "grandiose", "handsome", "impressive", "intelligent", "intoxicating", "inviting", "jolly", "joyful", "joyous", "jubilant", "keen", "lavish", "lovely", "luscious", "lush", "luxurious", "magnetic", "magnificent", "majestic", "marvelous", "mighty", "modern", "opulent", "penetrating", "peppy", "perceptive", "perky", "phenomenal", "pleasant", "plush", "pointed", "pretty", "profound", "quiet", "radiant", "refined", "remarkable", "ritzy", "sapient", "saucy", "savvy", "scintillating", "seductive", "sensational", "sensible", "sharky", "sharp", "showy", "shrewd", "slick", "smart", "sparkling", "spectacular", "splendid", "sporty", "sprightly", "striking", "stunning", "stupendous", "stylish", "sublime", "sumptuous", "superb", "superior", "swank", "tantalizing", "vibrant", "vivacious", "wonderful", "wondrous"] 

  LOCATION_NOUNS = ["locale", "community", "neighborhood", "location"]

  AMENITIES = ["balcony", "pool", "gym", "hot tub", "tennis", "basketball"]
 
  BR_PRE = [";"]
  BR = ["br","bed"]

  def self.generate(params={})
    o = { :bedrooms => 0,
          :type => "",
          :location => "",
          :amenities => ""}.merge(params)

    br = (o[:bedrooms] == 0 or o[:bedrooms].nil?) ? "" : "#{o[:bedrooms]}#{BR.sample}"
    type = (o[:type] or "unit")
    location = (o[:location] or LOCATION_NOUNS.sample)
    amenities_array = []

    for potential_amenity in AMENITIES
      if o[:amenities] =~ /#{potential_amenity}/
        amenities_array << (potential_amenity + (["tennis","basketball"].include?(potential_amenity) ? " court" : ""))
      end
    end

    amenities = amenities_array.reject{|a| a.nil? or a.empty?}
    if amenities.size > 1
      amenities = amenities[0..-2].join(", ") + " and " + amenities[-1]
    elsif amenities.size == 1
      amenities = amenities.first
    else
      amenities = ""
    end

    bedrooms  = [
                  [BR_PRE.sample, "#{ADJECTIVES.sample} #{br} #{type}"],
                  [BR_PRE.sample, "#{ADJECTIVES.sample} #{type}#{", "+br if !br.empty?}"]
                ].sample

    location  = [
                  [INS.sample, "#{ADJECTIVES.sample} #{location}"]
                ].sample

    amenities = [
                  [amenities.empty? ? nil : ","                  , amenities.empty? ? nil : "#{amenities} #{POST.sample}"],
                  [amenities.empty? ? nil : ", apt " + WITHS.sample, amenities.empty? ? nil : amenities]
                ].sample

    if amenities[0].nil? or amenities[1].nil?
      title_parts = [bedrooms, location].shuffle
    else
      title_parts = [bedrooms, location, amenities].shuffle
    end
    #puts "Parts : #{title_parts.to_s}"

    title = [ 
              title_parts[0][1],
              title_parts[0][1].nil? ? nil : title_parts[1][0],
              title_parts[1][1]
            ]
    if !amenities[0].nil? and !amenities[1].nil?
      title += [
                (title_parts[0][1].nil? and title_parts[1][1].nil?) ? nil : title_parts[2][0],
                 title_parts[2][1]
               ]
    end
    
    #puts "Pre replace : #{title.to_s}"
    title = title.join(" ").gsub(/[ ]*([ ,;])/,'\1')

    title = TRANSFORMS.sample.call(title)

    #puts "Pre truncated : \"#{title}\""
    while title.length > 70
      title = title.split(/ /)[0..-2].join(' ')
    end
    
    #all possible options for surrounding characters
    brackets = "{} [] ** <> >< ~~ :: -- ++ == '' __ ## !! $$ () )(".split(" ") << "  " << "\\/" << "/\\"
    brackets = brackets.collect{|b| b.split('')}.sample
    max = rand(11)
    max = max - max % 2 #give even number
    index = -1
    while title.length <= 69
      index += 1
      break if index >= max

      #puts "(#{index} of #{max})"
      (title = title + " "; next) if (index == 0 and title.last  != " ")
      (title = " " + title; next) if (index == 1 and title.first != " ")
      
      if index % 2 == 0
        title = title + brackets[1]
      else
        title = brackets[0] + title
      end
    end
    
    return title
  end
end
