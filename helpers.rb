helpers do

  def teaching_videos_dir
    File.join(File.dirname(__FILE__), "public/#{TEACHING_VIDEOS}")
  end

  def dancing_video_dir
    File.join(File.dirname(__FILE__), "public/#{DANCING_VIDEOS}")
  end

  # check_videos_subdir(dir)  looks into the subdirectory DIR of the teaching videos directory,
  # and returns an info nugget that contains...

  # we expect the sudirectory has a structure like
  # 01/somename.mp4
  # 01/caption.img

  Struct.new('Video', :caption, :htmlpath, :type, :subdir)

  def check_video_subdir dir
    caption    = nil
    htmlpath   = nil
    type       = nil
    subdir     = dir
    Dir.new(File.join(teaching_videos_dir, dir)).each do |filename|  # e.g. look in teaching-video/01 at each filename FILENAME
      case filename
      when /\.mp4$/i    # TODO: add more as necessary
        htmlpath = [ "/#{TEACHING_VIDEOS}", dir, filename ].join('/')
        type = :flash
      when /\.ogv$/i
        htmlpath = [ "/#{TEACHING_VIDEOS}", dir, filename ].join('/')
        type = :native
      when /caption/i  
        caption = File.read(File.join(teaching_videos_dir, dir, filename)).strip
      end
    end
    return htmlpath.nil? ? nil : Struct::Video.new(caption, htmlpath, type, subdir)
  end

  # teaching_video_selections - return a list of structs < :caption :htmlpath :type :subdir > associated
  # with each subdirectory under the teaching_videos_dir().

  def teaching_video_selections
    list = []
    Dir.new(teaching_videos_dir).each do |subdir|
      next unless File.directory? (File.join(teaching_videos_dir, subdir))
      next if subdir =~ /^\./
      list.push subdir
    end
    list.sort!

    candidates = []
    list.each do |subdir|
      video_data = check_video_subdir(subdir)
      candidates.push video_data unless video_data.nil?
    end
    candidates
  end

  # Return the marquee data, or, if data is supplied, save it as marquee data.

  def marquee_data new_data = nil
    yml = File.join(DATA_DIR, 'marquee.yml')
    if new_data
      open(yml, 'w') { |fh| fh.write new_data.to_yaml }
    else
      begin
        return YAML::load(File.open(yml))
      rescue
        marquee_data( { :beginning => 900, :intermediate => 900, :advanced => 900, :timestamp => Time.now.to_i } )   # just make something up to start  ###
        return marquee_data
      end
    end
  end

  # we are supposed to get time in minutes (an integer) from form submissions.
  # here we convert it to seconds.  If there's an error in conversion, we'll return zero

  def safe_seconds minutes_supposedly
    minutes_supposedly.to_i * 60
  rescue
    return 0
  end

  # Are we in teaching or dance mode?  Return one of :teaching, :dancing; if 
  # data is supplied, set the mode to that.

  def mode new_mode = nil
    :teaching
  end

end
