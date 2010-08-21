require 'yaml'
require 'helpers'


TEACHING_VIDEOS = 'teaching-videos'
DANCING_VIDEOS  = 'dancing-videos'
DATA_DIR        = '/tmp'



get '/' do
  if mode == :teaching
    redirect '/teaching', 302
  else
    redirect '/dancing', 302
  end
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
  erb :'ctl-marquee', :locals => { :data => marquee_data }
end

get '/ctl/teaching-video/?' do
  if params['video']
    redirect "/#{TEACHING_VIDEOS}/#{params['video']}", 302
  else
    erb :'ctl-teaching-video', :locals => { :selections => teaching_video_selections }
  end
end
  
post '/ctl/marquee' do

  if params['action'] !~ /no change/i
    now = Time.now.to_i
    
    data = Hash.new

    data[:beginning]    = safe_seconds params['beginning']
    data[:intermediate] = safe_seconds params['intermediate']
    data[:advanced]     = safe_seconds params['advanced']
    
    # when someone uses the marquee setup, they are specifying that
    # one of the states in the sequence beginning => intermediate =>
    # advanced has already been completed. So if, say, the beginning
    # dance has started, we'll roll back the start time by the length
    # of the beginning dance, so when we need to know our current
    # state we'll get it right...

    case params['action']
    when 'beginning'
      start = now - data[:beginning]
    when 'intermediate'
      start = now - (data[:beginning]  + data[:intermediate])
    when 'advanced'
      start = now - (data[:beginning]  + data[:intermediate] + data[:advanced])
    else
      start = now  # don't know what else to do... (can't happen)
    end

    data[:start] = start

    marquee_data data
  end
  redirect '/', 302

end


