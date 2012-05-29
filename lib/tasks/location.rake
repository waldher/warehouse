namespace :location do
  desc "Add A Location"
  task :add => :environment do
    print "Enter Craigslist Subdomain:"
    subdomain = STDIN.gets.strip
    
    agent = Mechanize.new
    page = agent.get("http://#{subdomain}.craigslist.org")
    location_name = page.root.css("div#topban h2").text.titlecase

    sublocations = {}
    for link in page.root.css("span.sublinks").children
      sublocations[link["href"].gsub("/","")] = link["title"].titlecase
    end
    
    location = Location.find_or_create_by_name_and_url(location_name, subdomain.downcase)

    if location.errors.empty?
      for url, name in sublocations
        sublocation = Sublocation.find_or_create_by_name_and_url_and_location_id(name, url, location.id)
      end
    else
      puts "Problem Saving Location"
      puts location.errors
    end
  end
end
