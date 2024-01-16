class VLCControl
  def self.instance
    @@instance ||= VLCControl.new
  end

  def initialize
    reset_sleep_timer
  end

  def reset_sleep_timer
    @sleep_thread.kill if @sleep_thread
    @sleep_thread = Thread.new do
      sleep(60 * 60 * 2) # 2 hours
      pause
    end
  end

  def go_to_channel(name)
    # VLC must be configured with HTTP access (port 8080 by default) and password 'tvm3u'

    # Clear the playlist
    curl("?command=pl_empty")

    # Open the new playlist
    resp = curl("?command=in_play&input=http://127.0.0.1:1337/channel/#{name}.m3u")

    # Ensure looping is on
    toggle_loop if resp.include?('<loop>false</loop>')
  end
  
  def pause
    curl("?command=pl_pause")
  end
  
  private


  def toggle_loop
    curl("?command=pl_loop")
  end

  def curl(params)
    status_url = 'http://127.0.0.1:8080/requests/status.xml'
    `curl -s -u :tvm3u '#{status_url}#{params}'`
  end
end