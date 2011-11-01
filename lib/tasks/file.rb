require 'yaml'

path = '../plumpads/'
listing_files_path = File.join(path)
Dir.foreach(listing_files_path) do |file|
  next if file =~ /^[.]/
  opened_file = File.open(File.join(path, file), "r")
  p opened_file.read.chomp.split("\r\n")
  break
end
