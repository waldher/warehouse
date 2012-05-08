class Word < ActiveRecord::Base
  belongs_to :definition

  def synonyms
    definition_ids = Word.where("ignore = ? and spelling = ?", false, self.spelling).collect(&:definition_id)
    
    Word.where("definition_id in (?) and ignore = ?", definition_ids, false).collect(&:spelling)

  end

  def self.synonyms(spellings)
    spellings = [spellings] if spellings.is_a?(String)
    spellings.map!{|s| s.downcase }

    definition_ids = Word.where("ignore = ? and spelling in (?)", false, spellings).collect(&:definition_id)

    adj_ids = []; nou_ids = []; sat_ids = []
    Synonym.where("definition_id in (?) and symbol not in (?)", definition_ids, [""]).each{|s| 
      adj_ids << s.wordnet_number if s.category == 'a'
      nou_ids << s.wordnet_number if s.category == 'n'
      sat_ids << s.wordnet_number if s.category == 's'
      #puts ""
      #puts "#{s.symbol} - #{s.wordnet_number} - #{s.category}"
      #puts Definition.where(:wordnet_number => s.wordnet_number, :category => s.category).sample.text_definition
      #for w in Definition.where(:wordnet_number => s.wordnet_number, :category => s.category).sample.words
      #  puts w.spelling
      #end
    }

    definition_ids = Definition.where("(wordnet_number in (?) and category = 'a') or
                                       (wordnet_number in (?) and category = 'n') or
                                       (wordnet_number in (?) and category = 's')", adj_ids,nou_ids,sat_ids).collect(&:id)

    return Word.where("definition_id in (?) and ignore = ?", definition_ids, false).collect(&:spelling)
  end
end
