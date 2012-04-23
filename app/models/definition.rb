class Definition < ActiveRecord::Base
  has_many :synonyms
  has_many :words

  def self.word_synonyms(spellings)
    query = Word.where("ignore = ?", false)
    if spellings.is_a?(String)
      query = query.where("spelling = ?", spellings)
    elsif spellings.is_a?(Array)
      query = query.where("spelling in (?)", spellings)
    end

    definition_ids = query.collect(&:definition_id)

    return Word.where("definition_id in (?) and ignore = ?", definition_ids, false).collect(&:spelling)
  end
end
