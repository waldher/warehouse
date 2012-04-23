class Synonym < ActiveRecord::Base
  belongs_to :definition
  belongs_to :synonym_definition, :foreign_key => :wordnet_number, :primary_key => :wordnet_number, :class_name => "Definition"
end
