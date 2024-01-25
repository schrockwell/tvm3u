require 'sinatra/base'

class Server < Sinatra::Base
  set :port, 1337
  set :bind, '0.0.0.0'
  
  # Fetched from VLC
  get '/channel/current.m3u' do
    content_type 'audio/x-mpegurl'
    TVM3U.current_m3u
  end

  # Controlled by user
  get '/' do
    send_file 'web/index.html'
  end

  # Controlled by user
  post '/go/next' do
    puts '--> Channel up'
    TVM3U.advance_channel(1)
    TVM3U.reload
    TVM3U.reset_sleep_timer
    send_file 'web/index.html'
  end
  
  # Controlled by user
  post '/go/prev' do
    puts '--> Channel down'
    TVM3U.advance_channel(-1)
    TVM3U.reload
    TVM3U.reset_sleep_timer
    send_file 'web/index.html'
  end
  
  post '/toggle-crop' do
    puts '--> Toggle crop'
    TVM3U.toggle_crop
    send_file 'web/index.html'
  end
end