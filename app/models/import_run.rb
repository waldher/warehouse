require 'json'

class ImportRun < ActiveRecord::Base
  def input_parsed
    return JSON.parse(input)
  end
end
