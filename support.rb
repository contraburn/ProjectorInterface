helpers do

  # logic for dance cycle. If you change this, you may need to change the rollback settings
  # in app.rb in the "post '/ct/marquee'" section.

  def marquee_string

    data = marquee_data()
    now  = Time.now.to_i
 
    cycle_duration = data[:beginning] + data[:intermediate] + data[:advanced]  # length of entire run of dance cycle in seconds

    return ". . . . . . . . . . . . . ." if cycle_duration == 0

    cycle_number  = (now - data[:start]) / cycle_duration   # which cycle we're on
    cycle_elapsed = (now - data[:start]) % cycle_duration   # where we are in the current cycle

    dances = []
    accum = 0
    [:beginning, :intermediate, :advanced].each do |state|
      time = data[state]
      next if time == 0
      dances.push( { :state => state, :begins => accum } )
      accum += time
    end

    later_dances = dances.select { |dance| dance[:begins] > cycle_elapsed }

    if later_dances.empty?
      next_state = dances[0][:state]
      next_start = cycle_duration - cycle_elapsed
    else
      next_state = later_dances[0][:state]
      next_start = later_dances[0][:begins] - cycle_elapsed
    end

    minutes = (next_start + 30) / 60  # add 30 seconds to round up.

    message = if next_start < 60
                "Starting Shortly"
              elsif next_start < 90
                "Starting In 1 Minute"
              else
                "Starting In #{minutes} Minutes At " + (Time.now + next_start).strftime('%I:%M %p')
              end

    ## message += '  :' + (['!', '@', '#', '%', '^', '&', '*', '+', '='].sort_by {rand}).pop

    return case next_state
           when :advanced
             "Next Up: An Advanced Dance " + message
           when :intermediate
             "Next Up: An Intermediate Dance " + message
           when :beginning
             "Next Up: A Beginning Dance " + message
           end
  end

  # conditional pluralize:

  def esses count, singular_form, plural_form = nil
    plural_form = singular_form + 's' unless plural_form
    count == 1 ? singular_form : plural_form
  end

  def teaching_videos_dir
    File.join(File.dirname(__FILE__), "public/#{TEACHING_VIDEOS}")
  end

  def dancing_video_dir
    File.join(File.dirname(__FILE__), "public/#{DANCING_VIDEOS}")
  end

  # check_videos_subdir(dir)  looks into the subdirectory DIR of the teaching videos directory,
  # and returns an info nugget that contains...

  # we expect each sudirectory to have contents like:
  #
  # 01/somename.vid   - where '.vid' is one of '.ogv' or 'mp4'
  # 01/caption.img    - where '.img' is any of '.png' '.jpg' '.jpeg' or '.gif'

  Struct.new('Video', :caption, :htmlpath, :type, :subdir)

  ### TODO:  switch to caption image instead of text.

  def check_video_subdir dir
    caption    = nil
    htmlpath   = nil
    type       = nil
    subdir     = dir
    Dir.new(File.join(teaching_videos_dir, dir)).each do |filename|  # e.g. look in teaching-video/01 at each filename FILENAME
      case filename
      when /\.mp4$/i
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

  # Read and return the marquee data, or, if data is supplied, save it to a data file

  def marquee_data new_data = nil
    yml = File.join(DATA_DIR, 'marquee.yml')
    if new_data
      open(yml, 'w') { |fh| fh.write new_data.to_yaml }
    else
      begin
        return YAML::load(File.open(yml))
      rescue
        marquee_data( { :beginning => 600, :intermediate => 600, :advanced => 600, :timestamp => Time.now.to_i } )   # just make something up to start
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

  #### TODO - make this read from a data file...

  def mode new_mode = nil
    :dance
  end
end
