namespace :log do
  desc "Read heathrow_logging bucket and extract request data from each file and fill database for statistics"
  task :import => :environment do
    puts bucket =  AWS::S3::Bucket.find("heathrow_logging")

    bucket.objects.each do |object|

      # Check for filename if not exists add to the database to keep track of files
      filename = object.key
      log_file = LogFile.find_or_initialize_by_filename(filename)

      # Check next object(file) if this file is read before
      is_new = log_file.new_record? ? true : false
      next unless is_new

      log_file.save!

      # Get data of read file and decompress it
      gz = Zlib::GzipReader.new(StringIO.new(object.value))

      # Read string(data) from the decompress file(data)
      unzipped = gz.read

      # Separate Version, Header and Request information
      unzip_to_array = unzipped.split("\n")

      # Version 
      version = unzip_to_array[0]

      # Header 
      header = unzip_to_array[1]

      # Reqest Information, which is tab separated values so can split with \s 
      request_info = unzip_to_array[2]

      request_array = request_info.split("\s")

      # Request Date is at 0 index
      date = request_array[0]

      # Request Time at 1 index
      time = request_array[1]

      time_array = date.split("-") + time.split(":")
      #p time_array 
      #p Time.utc(*time_array)
      #p Time.gm(*time_array)
      #p Time.local(*time_array)
      #p Time.new(*time_array)
      #break

      requested_time = Time.parse("#{date} #{time}")

      # Request IP(Internet Protocal) address at index 4
      ip_address = request_array[4]

      # Request Method(Verb) at index 5
      # Request Host(not sure yet) at index 6
      # Request Path at index 7
      path = request_array[7]

      # path have two informations directory and filename
      # r = %r((^/.+/)(.+..)) 1: directory, 2: filename with extension
      # r = %r((^/.+/)(.+\.(.+))) 1:directory, 2: filename with extension, 3: extension
      # r = %r(^/(.+)/(.+\.(.+))) same as above but stripped trailing and leading slashes from directory
      r = %r(^/(.+)/(.+\.(.+)))
      path_array = path.split(r)
      directory = path_array[1]
      filename = path_array[2]
      extension = path_array[3]
      p "#{directory} -> #{filename} -> #{extension}"
      p request_array if directory.nil? || filename.nil? || extension.nil?

      directory_object = Directory.find_or_create_by_name(directory)
      options = {
        :ip_address => ip_address, 
        :filename => filename,
        :click => (extension.try(:downcase).try(:eql?, "html") ? true : false),
        :requested_at => requested_time,
        :raw => request_info
      }
      file_object = DirectoryFile.create(options)
      directory_object.files << file_object


      # Request response status(200/302/404) code at index 8
      # Request Referer at index 9
      # Request Agent at index 10
      # Request QueryString part at index 11
    end

    #  puts object.content_type
    #
    #  puts object.about
    #
    #  puts "======================"
    #  puts object.metadata
    #  puts "======================"
    #  #puts object.metadata[:version] = 1
    #  #object.store
    #
    #
    #  puts gz = Zlib::GzipReader.new(StringIO.new(object.value))
    #
    #  puts "======================"
    #  puts gz.read.class
    #  puts "======================"
    #end

  end
end
