class Role < ActiveRecord::Base
  has_many :customers
end
