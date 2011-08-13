class RealEstate < ActiveRecord::Base
  belongs_to :realtor, :foreign_key => :realtor_id
  has_attached_file :photo,
    :styles => {
    :thumb=> "100x100#",
    :small  => "400x400>" },
    :storage => :s3,
    :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
    :path => "/:style/:id/:filename"
end
