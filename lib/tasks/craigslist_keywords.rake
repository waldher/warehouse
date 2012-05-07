require 'mechanize'

namespace :craigslist_keywords do
  desc "Import Craigslist Keywords"
  task :import => :environment do
    cities = ["miami", "tampa", "dallas", "houston", "phoenix", "losangeles", "sfbay", "seattle", "minneapolis", "chicago", "philadelphia"]

    agent = Mechanize.new
    ad_urls = []

    for city in cities
      page = agent.get("http://#{city}.craigslist.org/apa/")

      20.times {|i|
        ad_links = page.links.reject{|l| !(l.href =~ /[0-9]{5,}[.]html$/) }
        ad_links.each{|l| ad_urls << l.href }
        page = page.link_with(:text => "next 100 postings").click
      }
    end

    ad_urls.uniq!

    words_hash = {}

    ad_urls.each{|ad_url|
      begin
        ad = agent.get(ad_url)
        text = ad.at('div#userbody').text
        text.gsub!(/[^A-Za-z-]/, ' ')
        text.gsub!(/---*/, ' ')
        words = text.split(/\s\s*/)
        words.each{|word_in|
          word = word_in.downcase
          if word.size < 2
            next
          end

          if words_hash.has_key?(word)
            words_hash[word] += 1
          else
            words_hash[word] = 1
          end
        }
      rescue => e
      end
    }

    words_hash.reject!{|k, v| v == 1}
    sorted = {}
    words_hash.each{|k, v|
      if Word.find_by_spelling(k).nil?
        next
      end

      if sorted.has_key?(v)
        sorted[v] << k
      else
        sorted[v] = [k]
      end
    }

    sorted.sort.each{|v, k|
      k.each{|word|
        CraigslistKeyword.create(:frequency => v, :spelling => word)
      }
    }
  end
end
