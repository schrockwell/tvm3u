#! /usr/bin/env ruby

require_relative 'lib/app_state'
require_relative 'lib/server'
require_relative 'lib/vlc_control'

if __FILE__ == $0
  Thread.new do
    sleep 1
    VLCControl.instance.go_to_channel('current')
  end
  
  Server.run!
end