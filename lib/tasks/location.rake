namespace :location do
  desc "Add A Location"
  task :add => :environment do
    print "Enter Craigslist Subdomain:"
    subdomain = STDIN.gets.strip
    
    agent = Mechanize.new
    page = agent.get("http://#{subdomain}.craigslist.org")
    location_name = page.root.css("div#topban h2").text.titlecase
    sublocations = {}
    page.root.css("span.sublinks").children.each{|link|
      sublocations[link["href"].gsub("/","")] = link["title"]
    }

    location = Location.create(:name => location_name, :url => subdomain)

    if location.errors.empty?
      sublocations.each{|k,v|
        Sublocation.create(:name => v, :url => k, :location_id => location.id)
      }
    end
    end
end
