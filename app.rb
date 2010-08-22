require 'yaml'
require 'support'

TEACHING_VIDEOS     = 'teaching-videos'
DANCING_VIDEOS      = 'dancing-videos'
DATA_DIR            = '/tmp'               #### TODO: definition to settings, via config.ru
SELECTIONS_PER_PAGE = 5


get '/' do
  if mode == :dance
    redirect '/dance', 302
  else
    redirect '/teach', 302
  end
end

get '/dance/?' do
  data = dance_data
  erb :dance, :locals => { :marquee_text => marquee_string(), 
                           :left_video_html_path  => data[:lhs],
                           :right_video_html_path => data[:rhs],
                           :caption_image_path    => data[:caption]
  }
end


# render the teaching video directory

get '/teach/?' do
  data = teach_data
  erb :teach, :locals => { :marquee_text => marquee_string(), 
                           :video_html_path => data.video_htmlpath, 
                           :caption_image_path => data.caption_htmlpath 
  }
end


# A page for getting at the marquee string, which we'll retrieve via ajax from /dance and /teach pages.

get '/marquee/?' do
  marquee_string
end

# 
get '/ctl/mode' do
  erb :'ctl-mode', :locals => { :current_mode => mode }
end

post '/ctl/mode' do
  case params['action']
  when  /no change/i
    redirect '/', 302
  when  /dance/i
    mode :dance
    redirect '/dance', 302
  when  /teach/i
    #  mode :teach 
    redirect '/ctl/teach-select/1', 302
  end
  redirect '/', 302
end


post '/ctl/teach-select/:page' do
  dir = (params['action'].split(' - '))[0]
  mode_data({ :mode => :teach, :selected_teaching_video => dir })
  redirect '/', 302
end



# select one of the teaching videos

get '/ctl/teach-select/?' do
  redirect '/ctl/teach-select/1', 302  # go to page 1
end


# paginate the list of teaching videos

get '/ctl/teach-select/:page'  do |page|

  page_num = page.to_i

  list = teaching_video_selections()
  page_list = list[ (page_num - 1) * SELECTIONS_PER_PAGE .. (page_num * SELECTIONS_PER_PAGE) - 1]

  redirect '/ctl/teach-select/1', 302 unless page_list

  total_pages = (list.length + (SELECTIONS_PER_PAGE - 1)) / SELECTIONS_PER_PAGE
  
  erb :'ctl-teach-select', :locals => 
    { :selections    =>  page_list,
      :previous_page =>  page_num - 1,
      :previous_text => (page_num == 1 ? '': 'Previous'),
      :next_page     =>  page_num + 1,
      :next_text     => (page_num >= total_pages ? '': 'Next'),
    }
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
