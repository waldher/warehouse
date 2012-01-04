class Directory < ActiveRecord::Base
  has_many :files, :class_name => "DirectoryFile"
end
