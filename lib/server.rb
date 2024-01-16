require 'sinatra/base'

class Server < Sinatra::Base
  set :port, 1337
  set :bind, '0.0.0.0'
  
  get '/channel/current.m3u' do
    content_type 'audio/x-mpegurl'
    AppState.instance.current_m3u
  end

  get '/channel/next.m3u' do
    content_type 'audio/x-mpegurl'
    AppState.instance.next_m3u(1)
  end

  get '/channel/prev.m3u' do
    content_type 'audio/x-mpegurl'
    AppState.instance.next_m3u(-1)
  end

  get '/go/next' do
    puts '--> Channel Up'
    VLCControl.instance.go_to_channel('next')
    VLCControl.instance.reset_sleep_timer
    'OK'
  end
  
  get '/go/prev' do
    puts '--> Channel down'
    VLCControl.instance.go_to_channel('prev')
    VLCControl.instance.reset_sleep_timer
    'OK'
  end

  get '/go/play' do
    puts '--> Play'
    VLCControl.instance.go_to_channel('current')
    VLCControl.instance.reset_sleep_timer
    'OK'
  end

  get '/go/pause' do
    puts '--> Pause'
    VLCControl.instance.pause
    'OK'
  end
end