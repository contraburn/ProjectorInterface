helpers do

  # TODO: select a video directory default? The first video? Shit? Go blind?

  def mode_data new_data = nil
    yml = File.join(DATA_DIR, 'mode.yml')
    if new_data
      open(yml, 'w') { |fh| fh.write new_data.to_yaml; fh.fsync }
    else
      begin
        return YAML::load(File.open(yml))
      rescue
        mode_data( { :mode => :dance, :selected_teaching_video =>  nil } )   # just make something up to start off...
        return mode_data
      end
    end
  end

  # Get our current mode: new_mode, if present, is one of :dance or
  # :teach, which will be saved in a YAML file.

  def mode new_mode = nil
    data = mode_data()
    if new_mode
      data[:mode] = new_mode  
      mode_data data
    end
    data[:mode]
  end

  # Read and return the hash stored in the marquee datafile (a YAML
  # file), or, if data is supplied, store it to that file.  The data
  # are in a simple hash containing:
  #
  #    :timestamp    - time in epoch format, for when we start the cycle
  #    :beginning    - the length in seconds of the beginning dance
  #    :intermediate - the length in seconds of the intermediate dance
  #    :advanced     - the length in seconds of the advanced dance
  #
  # the times for the types of dances may be zero, which means that dance
  # is skipped.

  # The contents of the data file are simple text strings.

  def marquee_data new_data = nil
    yml = File.join(DATA_DIR, 'marquee.yml')
    if new_data
      open(yml, 'w') { |fh| fh.write new_data.to_yaml; fh.fsync }
    else
      begin
        return YAML::load(File.open(yml))
      rescue
        marquee_data( { :beginning => 600, :intermediate => 600, :advanced => 600, :timestamp => Time.now.to_i } )   # just make something up to start
        return marquee_data
      end
    end
  end

  # marquee_string - contains logic (if you can call it that) for
  # computing the dance cycle. If you change this around, you may need
  # to change the rollback settings in app.rb in the "post
  # '/ct/marquee'" section. (for instance, if change the order of the
  # dances or add a a 'break' in the cycle...).

  # This is where you change the marquee string displayed.

  def marquee_string

    data = marquee_data()
    now  = Time.now.to_i
 
    cycle_duration = data[:beginning] + data[:intermediate] + data[:advanced]  # length of entire run of dance cycle in seconds

    return ". . . . . . . . . . . . . ." if cycle_duration == 0   # just something to click on, to jump to the control marquee page

    cycle_number  = (now - data[:start]) / cycle_duration   # which cycle we're on
    cycle_elapsed = (now - data[:start]) % cycle_duration   # where we are in the current cycle

    # make an array, dances, that gives the start times for each dance in the cycle, starting from zero.
    # So if each dance lasted 5 minutes, this would look like:
    #
    #  [ { :state => :beginning, :begins => 0 }, { :state => :intermediate, :begins => 300 }, { :state => :advanced, :begins => 600 } ]

    dances = []
    accum = 0
    [:beginning, :intermediate, :advanced].each do |state|
      time = data[state]
      next if time == 0
      dances.push( { :state => state, :begins => accum } )
      accum += time
    end

    # filter dances to those that start later than the current point
    # in the cycle; the first one is the next dance.  if there are
    # none, we'll have to wrap around to the first one.

    later_dances = dances.select { |dance| dance[:begins] > cycle_elapsed }

    if later_dances.empty?
      next_state = dances[0][:state]
      next_start = cycle_duration - cycle_elapsed
    else
      next_state = later_dances[0][:state]
      next_start = later_dances[0][:begins] - cycle_elapsed
    end

    minutes = (next_start + 30) / 60   # add 30 seconds to round up.

    message = if next_start < 60
                "Starting Shortly"
              elsif next_start < 90
                "Starting In 1 Minute"
              else
                "Starting In #{minutes} Minutes At " + (Time.now + next_start).strftime('%I:%M %p')  # (Time + integer seconds) give us another Time object
              end

    ## test mode: randomly append something so we can see we're getting updates.
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

  # Conditional pluralize: don't think I use this (TODO: check)

  def esses count, singular_form, plural_form = nil
    plural_form = singular_form + 's' unless plural_form
    count == 1 ? singular_form : plural_form
  end

  # The directories containing the video files are returned here; the
  # constants TEACHING_VIDEOS and DANCING_VIDEOS are defined at the
  # top of 'app.rb'

  def dancing_videos_dir
    File.join(File.dirname(__FILE__), "public/#{DANCING_VIDEOS}")
  end

  def teaching_videos_dir
    File.join(File.dirname(__FILE__), "public/#{TEACHING_VIDEOS}")
  end

  # teach_data - potential problem here, the video dir might not have been selected yet...

  def teach_data
    data = mode_data 
    return check_video_subdir(data[:selected_teaching_video])       
  end
    
  

  # dance_data - returns a hash with the URL paths to the appropriate files for
  # the two videos and one 
  # gotta be:  lhs.<vid>, rhs.<vid>, caption.<img> where:
  #  vid  is one of ogv, mp4
  #  img  is one of png, jpeg, jpg, gif  (why do I think I'm forgetting a format?)

  def dance_data

    data = { :lhs => nil, :rhs => nil, :caption => nil }

    Dir.new(File.join(dancing_videos_dir)).each do |filename|  # e.g. look in directory dancing-videos/

      case filename
      when /^lhs/i
        data[:lhs]     = '/' + File.join(DANCING_VIDEOS, filename)  
      when /^rhs/i
        data[:rhs]     = '/' + File.join(DANCING_VIDEOS, filename)  
      when /caption/i
        data[:caption] = '/' + File.join(DANCING_VIDEOS, filename)  
      end
    end
    
    return data
  end

  # check_videos_subdir(dir)  looks into the subdirectory DIR of the teaching videos directory,
  # and returns an info nugget that contains...

  # we expect each sudirectory to have contents like:
  #
  # 01/somename.vid   - where '.vid' is one of '.ogv' or 'mp4'
  # 01/caption.img    - where '.img' is any of '.png' '.jpg' '.jpeg' or '.gif'
  #
  #  We return a struct with three elements:
  #
  #   .subdir gives us the video subdirectory, '01' in the above example
  #   .caption_htmlpath is the URL path to the caption image file
  #   .video_htmlpath is the URL path to the teaching video file
  
  Struct.new('Video', :caption_htmlpath, :video_htmlpath, :subdir, :name)

  def check_video_subdir dir
    caption_htmlpath = nil
    video_htmlpath   = nil
    name             = nil
    subdir           = dir

    Dir.new(File.join(teaching_videos_dir, dir)).each do |filename|  # e.g. look in teaching-video/01 at each filename FILENAME
      case filename
      when /(.*)\.mp4$/i
        name = $1
        name.gsub!(/[_-]/, ' ')
        video_htmlpath = [ "/#{TEACHING_VIDEOS}", dir, filename ].join('/')
      when /(.*)\.ogv$/i
        name = $1
        name.gsub!(/[_-]/, ' ')
        video_htmlpath = [ "/#{TEACHING_VIDEOS}", dir, filename ].join('/')
      when /caption\.(jpg|jpeg|gif|png)$/i  
        caption_htmlpath =  [ "/#{TEACHING_VIDEOS}", dir, filename ].join('/')
      end
    end
    return video_htmlpath.nil? ? nil : Struct::Video.new(caption_htmlpath, video_htmlpath, subdir, name)
  end

  # teaching_video_selections - return a list of structs of the form:
  # 
  #  [  < :caption_htmlpath :video_htmlpath :subdir > , .... ]
  # 
  # associated with each subdirectory under the teaching_videos_dir().
  # See above for the element's struct.

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

  # We are supposed to get time in minutes (an integer) from form
  # submissions.  Here we convert it to seconds.  If there's an error
  # in conversion (say someone enters junk in the form text input),
  # we'll just return zero.

  def safe_seconds minutes_supposedly
    minutes_supposedly.to_i * 60
  rescue
    return 0
  end

end
