require 'yaml'
require 'support'

TEACHING_VIDEOS     = 'teaching-videos'
DANCING_VIDEOS      = 'dancing-videos'
DATA_DIR            = '/tmp'               #### TODO: definition to settings, via config.ru
SELECTIONS_PER_PAGE = 4

#### TODO: save mode, selected video

get '/' do
  if mode == :dance
    redirect '/dance', 302
  else
    redirect '/teach', 302
  end
end

#### TODO: change to check in directory for actual name

get '/dance/?' do
  erb :dance, :locals => { :marquee_text => marquee_string(), 
                           :left_video_html_path  => '/dancing-videos/rhs.mp4',
                           :right_video_html_path => '/dancing-videos/rhs.mp4',

                           # :left_video_html_path  => '/dancing-videos/lhs.ogv',
                           # :right_video_html_path => '/dancing-videos/lhs.ogv',

                           # :left_video_html_path  => '/dancing-videos/lhs.ogv',
                           # :right_video_html_path => '/dancing-videos/rhs.mp4',

                           :caption_image_path =>    '/images/dummy-caption.png'
  }
end

#### TODO: this should just be '/teach/?'  

get "/#{TEACHING_VIDEOS}/:subdir" do |subdir|
  data = check_video_subdir(subdir)     ## handle error condition here.  
  erb :"teaching-video", :locals => { :selection => data, :subdir => subdir, :marquee => read_marquee }
end

# A page for getting at the marquee string, which we'll retrieve via ajax from /dance and /teach pages.

get '/marquee/?' do
  marquee_string
end

#### TODO: create this to switch from dance/teach, or to go select a teaching video

get '/ctl/mode' do
  erb :'ctl-mode', :locals => { :current_mode => mode }
end

post '/ctl/mode' do

  if params['action'] !~ /no change/i
    params['action']
  else
    'no change'
  end

#  redirect '/', 302
end


# select one of the teaching videos

get '/ctl/teaching-video/?' do
  if params['video']
    redirect "/#{TEACHING_VIDEOS}/#{params['video']}", 302
  else
    erb :'ctl-teaching-video', :locals => { :selections => teaching_video_selections }
  end
end

# A page with a form for the marquee values:

get '/ctl/marquee/?' do
  erb :'ctl-marquee', :locals => { :data => marquee_data }
end

# The page for setting the marquee values from a form submission:

post '/ctl/marquee' do

  if params['action'] !~ /no change/i

    now = Time.now.to_i  # Unix epoch format (seconds since 1970)
    
    data = {}

    data[:beginning]    = safe_seconds params['beginning']        # record intervals for each dance in seconds
    data[:intermediate] = safe_seconds params['intermediate']
    data[:advanced]     = safe_seconds params['advanced']
    
    # When someone uses the marquee setup page they are specifying
    # that one of the states in the sequence beginning => intermediate
    # => advanced has already been completed. So we need to roll back
    # the start time to account for cases where we're starting in the
    # middle of cycle.

    # If you change the order of dances, you'll need to adjust these
    # rollbacks accordingly (see corresponding function marquee_string in
    # 'support.rb').

    data[:start] = case params['action']
                   when 'beginning'
                     now
                   when 'intermediate'
                     now - data[:beginning]
                   when 'advanced'
                     now - (data[:beginning]  + data[:intermediate])
                   else
                     now  # can't happen
                   end

    marquee_data data
  end

  redirect '/', 302
end
