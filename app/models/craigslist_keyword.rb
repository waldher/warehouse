class CraigslistKeyword < ActiveRecord::Base
  def self.filter(words)
    words = [words] if words.is_a?(String)

    return CraigslistKeyword.where("spelling in (?) and frequency > 10", words).collect(&:spelling)
  end
end
