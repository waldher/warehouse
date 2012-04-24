class ListingTitle
  MAX_TITLE_LENGTH = 70

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

  ADJECTIVES = ["Great",
                "Beautiful",
                "Nice",
                "Awesome",
                "Flashy",
                "Amazing",
                "Charming",
                "Cute",
                "Wonderful",
                "Gorgeous",
                "Superb",
                "Excellent",
                "Good",
                "Slick",
                "Divine",
                "Majestic",
                "Enjoyable",
                "Stunning",
                "Fabulous",
                "Very Nice",
                ]

  ADVERTISING_STRINGS = [ "Must see!",
                          "Too good to be true!",
                          "Look here!",
                          "Look no further!",
                          "Your search is over!",
                          "Unique!",
                          "Rare find!",
                          "Ready To View!",
                          "Ready To Show!",
                          "Check It Out!",
                          "Ready To Move In!",
                          "Dont wait!",
                          "Chance of a lifetime!",
                          "Pure Joy!",
                          "Wow!",
                          "Don't Miss Out!",
                          "Great Chance!",
                          "Great Opportunity!",
                          "Cant Believe Its Still Available!",
                          "Now Or Never!",
                          "What An Opportunity!",
                          "Looking For A Deal?",
                          ]

  TIME_LIMITS = [ "Hurry Wont Last!",
                  "Limited Offer!",
                  "Now Or Never!",
                  "Limited Opportunity!",
                  "Dont Wait!",
                  "Limited Time Only!",
                  ]

  AMENITIES = [ /Pool/i,
                /Gym/i,
                /Hot Tub/i,
                /Tennis/i,
                /Basketball/i,
                /Large Yard/i,
                /Parking/i,
                /Garage/i,
                /Exercise Room/i,
                /Tiled/i,
                /Terrace/i,
                /Terrace/i,
                /Sauna/i,
                /Patio/i,
                /Winter Garden/i,
                /Barbeque/i,
                /Vaulted Ceiling/i,
                /Furnished/i,
                /Sun Deck/i,
                /Walk-In Closet/i,
                /Walk-In Closets/i,
                /Art Decor/i,
                ]
  #TODO
  #ame9: [Material] Floors
  #ame11: [Material] Kitchen
  #ame22: New [Kitchen, etc.]
  #ame25: Large [dining, living, etc.] Room
  #ame26: [Ocean, Waterway, etc.] View

  PERKS = [ /Close To Beach/i,
            /Gated Community/i,
            /Live Security/i,
            /Close To Preserve/i,
            /Golf Course Close/i,
            /Near University/i,
            /Close[ \-]?By Shops/i,
            /Close To Public Transportation/i,
            /Close To Everything/i,
            /In Quiet Area/i,
            ]

  AGES = [/modern/i,
          /remodelled/i,
          /refurbished/i,
          /rustic style/i,
          /renovated/i,
          ]


  BR = ["br","bed","bd"]

  TEMPLATES = [ "[<til>] <rai> <adj> <bdr> [<age>] <top> In <loc>[<ame>][,<per>]",
                "<rai> [<age>] <adj> <top> with <bdr>[, <ame>][, <per>] In <loc>, [<til>]",
                "<adj> <top>, <bdr>[, <ame>] In <loc>[, <per>], <rai>, [<age>][<til>]",
                "<adj> [<age> ] <bdr> <top> in <loc>[, <per>,] [<til>, ]<rai> [<ame>]",
                "This [, <age>]<adj> <top> In <loc>[<ame>][, <per>] <bdr>s[, <til>], <rai>",
                ]

  def self.generate(listing)
    bdr = (listing.infos["ad_bedrooms"] == "0" or listing.infos["ad_bedrooms"].nil?) ? "" : "#{listing.infos["ad_bedrooms"]}#{BR.sample}"
    loc = (listing.infos["ad_location"] or "")
    top = ( listing.infos["ad_type"] or 
            ("townhouse" if (listing.infos["ad_description"] =~ /townhouse/i)) or 
            ("townhome" if (listing.infos["ad_description"] =~ /townhome/i)) or 
            ("duplex" if (listing.infos["ad_description"] =~ /duplex/i)) or 
            ("house" if (listing.infos["ad_description"] =~ /house/i)) or 
            ((listing.customer.craigslist_type == "apa" ? "apt" : "condo") if (listing.infos["ad_complex"] or 
                                                                              (listing.infos["ad_address"] =~ /(#|apt|suite|unit| ste )/i) or 
                                                                              (listing.infos["ad_description"] =~ /(apartment|condo)/i))) or 
             "")
    adj = ADJECTIVES.sample

    amenities_array = []
    for potential_amenity in AMENITIES
      match = potential_amenity.match(listing.infos["ad_amenities"]) or potential_amenity.match(listing.infos["ad_description"])
      if match
        amenities_array << match[0]
      end
    end
    ame = (amenities_array.sample or "")

    til = TIME_LIMITS.sample

    ages_array = []
    for potential_age in AGES
      match = potential_age.match(listing.infos["ad_description"])
      if match
        ages_array << match[0]
      end
    end
    age = (ages_array.sample or "")

    perks_array = []
    for potential_perk in PERKS
      match = potential_perk.match(listing.infos["ad_description"])
      if match
        perks_array << match[0]
      end
    end
    per = (perks_array.sample or "")

    rai = ADVERTISING_STRINGS.sample

    # BEGIN TEMPLATE GENERATION
    templates_list = TEMPLATES
    title = nil
    while title.nil? and !templates_list.empty?
      template = templates_list.sample
      prospect = String.new(template)

      prospect.gsub!(/<bdr>/, bdr)
      prospect.gsub!(/<loc>/, loc)
      prospect.gsub!(/<top>/, top)
      prospect.gsub!(/<adj>/, adj)
      prospect.gsub!(/<ame>/, ame)
      prospect.gsub!(/<til>/, til)
      prospect.gsub!(/<age>/, age)
      prospect.gsub!(/<per>/, per)
      prospect.gsub!(/<rai>/, rai)

      prospect.gsub!(/  */, ' ') # Remove double spaces

      base_title = prospect.gsub(/ *\[[^\[\]]*\] */, ' ')

      if base_title.length > 70
        templates_list -= [template]
        next
      end

      optional_match_list = []
      for optional_match in prospect.scan(/\[[^\[\]]*\]/)
        optional_match_list << optional_match[1..-2]
      end
      optional_match_list.shuffle
      
      for match in optional_match_list
        if (base_title.size + match.size) <= 70
          base_title = prospect.gsub(/\[#{match}\]/, match).gsub(/ *\[[^\[\]]*\] */, ' ').gsub(/^ */, '').gsub(/ *$/, '')
          prospect = prospect.gsub(/\[#{match}\]/, match)
        end
      end

      title = TRANSFORMS.sample.call(prospect.gsub(/ *\[[^\[\]]*\] */, ' ').gsub(/  */, ' ').gsub(/^ */, '').gsub(/ *$/, '').gsub(/[ ,]*,/, ','))
    end
    
    return title
  end
end
