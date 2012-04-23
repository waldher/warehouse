namespace :wordnet do
  desc "Import WordNet Data"
  task :import => :environment do
    if ENV['WORDNETFILE'].nil?
      raise "Environment variable WORDNETFILE is not set"
    end

    fp = File.open(ENV["WORDNETFILE"])

    if !fp
      raise "Couldn't open WordNet file"
    end
    
    for line in fp.read.lines
      matchdata = line.match(/^([0-9]+) [0-9][0-9] (n|v|a|s|r) [0-9a-f][0-9a-f] ([A-Za-z0-9_ ]*) [0-9][0-9][0-9] ([^|]*) \| (.*)/)

      if matchdata.nil?
        next
      end

      wordnet_number = matchdata[1].to_i
      category = matchdata[2]
      words = {}

      matchdata[3].scan(/([A-Za-z_]{2,}) ([0-9a-f])/){|wordmatch|
        words[wordmatch[0]] = wordmatch[1].to_i(16)
      }

      syns = {}

      matchdata[4].scan(/(.) ([0-9]{8}) (.) ([0-9a-f]{4})/){|synmatch|
        syns[synmatch[1].to_i] = synmatch[0]
      }

      text_definition = matchdata[5]

      definition = Definition.find_by_wordnet_number(wordnet_number)
      if definition.nil?
        definition = Definition.create(:wordnet_number => wordnet_number, :category => category, :text_definition => text_definition)
      end

      for spelling, sense in words
        word = Word.where("definition_id = ? and spelling = ?", definition.id, spelling).first
        if word.nil?
          word = Word.create(:definition_id => definition.id, :spelling => spelling, :sense => sense)
        end
      end

      for synonym_wordnet_number, symbol in syns
        synonym = Synonym.where("definition_id = ? and wordnet_number = ?", definition.id, synonym_wordnet_number).first
        if synonym.nil?
          synonym = Synonym.create(:definition_id => definition.id, :wordnet_number => synonym_wordnet_number, :symbol => symbol)
        end
      end
    end

    fp.close
  end
end
