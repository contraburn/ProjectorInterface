
TEACHING_VIDEOS = 'teaching-videos'

helpers do

  def teaching_video_dir
    File.join(File.dirname(__FILE__), "public/#{TEACHING_VIDEOS}")
  end

  # expect a directory structure like
  # 01/
  # 01/somename.mp4
  # 01/caption

  Struct.new('Video', :caption, :htmlpath, :type, :subdir)

  def check_video_subdir dir
    caption    = nil
    htmlpath   = nil
    type       = nil
    subdir     = dir
    Dir.new(File.join(teaching_video_dir, dir)).each do |filename|  # e.g. look in teaching-video/01 at each filename FILENAME
      case filename
      when /\.mp4$/i    # TODO: add more as necessary
        htmlpath = [ "/#{TEACHING_VIDEOS}", dir, filename ].join('/')
        type = :flash
      when /\.ogv$/i
        htmlpath = [ "/#{TEACHING_VIDEOS}", dir, filename ].join('/')
        type = :native
      when /caption/i  
        caption = File.read(File.join(teaching_video_dir, dir, filename)).strip
      end
    end
    return htmlpath.nil? ? nil : Struct::Video.new(caption, htmlpath, type, subdir)
  end

  
  # teaching_video_selections - return a list of structs < :caption :htmlpath :type :subdir > associated
  # with each subdirectory under the teaching_video_dir().

  def teaching_video_selections
    list = []
    Dir.new(teaching_video_dir).each do |subdir|
      next unless File.directory?(File.join(teaching_video_dir, subdir))
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

  def marquee_datafile
    File.join(File.dirname(__FILE__), 'data', 'marquee')
  end

  def read_marquee
    text = (File.read marquee_datafile).strip
  rescue => e
    e.message
  else
    text
  end

  def write_marquee text
    File.open(marquee_datafile, 'w') { |fh| fh.puts text }
  end

end

get '/' do
  redirect 'ctl', 302
end
 
get '/marquee.html' do
  erb :marquee, :locals => { :marquee_text => read_marquee }
end
 
get "/#{TEACHING_VIDEOS}/:subdir" do |subdir|
  data = check_video_subdir(subdir)     ## handle error condition here.  
  # type can be one of :native or :flash
  erb :"teaching-video", :locals => { :selection => data, :subdir => subdir, :marquee => read_marquee }
end

get '/ctl/?' do
  erb :'ctl-index'
end

get '/ctl/marquee/?' do
  erb :'ctl-marquee'
end

get '/ctl/teaching-video/?' do
  if params['video']
    redirect "/#{TEACHING_VIDEOS}/#{params['video']}", 302
  else
    erb :'ctl-teaching-video', :locals => { :selections => teaching_video_selections }
  end
end

post '/ctl/marquee/?' do
  write_marquee "Next up: #{params['dance']}, #{params['skill']} dance, in #{params['countdown']} minutes."
  redirect '/ctl/teaching-video', 302
end


