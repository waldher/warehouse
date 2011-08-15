class RealEstateImage < ActiveRecord::Base
  belongs_to :imageable, :polymorphic => true
  has_attached_file :photo,
     :storage => :s3,
    :s3_credentials => YAML.load_file(File.join(Rails.root, 'config', 's3.yml')),
    :s3_permissions => 'authenticated-read',
    :s3_protocol => 'http',
    :bucket => 'marsala_test',
    :path => "/:style/:id/:filename"
end
