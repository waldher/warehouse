class Word < ActiveRecord::Base
  belongs_to :definition

  def synonyms
    definition_ids = Word.where("ignore = ? and spelling = ?", false, self.spelling).collect(&:definition_id)
    
    return Word.where("definition_id in (?) and ignore = ?", definition_ids, false).collect(&:spelling)
  end

  def self.synonyms(spellings)
    spellings = [spellings] if spellings.is_a?(String)

    definition_ids = Word.where("ignore = ? and spelling in (?)", false, spellings).collect(&:definition_id)

    return Word.where("definition_id in (?) and ignore = ?", definition_ids, false).collect(&:spelling)
  end
end
