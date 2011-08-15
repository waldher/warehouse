require 'aws/s3'
if Rails.env == "development"
  S3_CREDENTIALS = { :access_key_id => "AKIAIZKCYKP7EC7TNX6A", :secret_access_key => "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", :bucket => "marsala_test", :server => "s3-ap-southeast-1.amazonaws.com"}
else
  S3_CREDENTIALS = Rails.root.join("config/s3.yml")
end
