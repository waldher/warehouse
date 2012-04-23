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
      matchdata = line.match(/^([0-9]+) [0-9][0-9] (n|v|a|s|r) [0-9a-f][0-9a-f] ([A-Za-z0-9_ '.-]*) [0-9][0-9][0-9] ([^|]*) \| (.*)/)

      if matchdata.nil?
        puts "For some reason '#{c(6)}#{line}#{ec}' does not conform to the expected wordnet datafile's format."
        puts "Please ensure that it is acceptable to exclude the line from the database."
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

      text_definition = matchdata[5].strip

      
      definition = Definition.find_or_create_by_wordnet_number_and_category_and_text_definition(wordnet_number, category, text_definition)

      for spelling, sense in words        
        Word.find_or_create_by_definition_id_and_spelling_and_sense(definition.id, spelling, sense)
      end

      for synonym_wordnet_number, symbol in syns
        Synonym.find_or_create_by_definition_id_and_wordnet_number_and_symbol(definition.id, synonym_wordnet_number, symbol)
      end
    end

    fp.close
  end
end

def ec; "\x1b[0m" end 

def c(fg,bg = nil)
  "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}" 
end 
