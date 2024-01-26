require 'json'
require 'socket'

class TVM3U
  SLEEP_TIMER = 60 * 60 * 2 # 2 hours
  CROPS = ['0:0', '4:3', '2:1']

  attr_reader :cropped

  def self.instance
    @@instance ||= TVM3U.new
  end

  def self.method_missing(method, *args, &block)
    instance.send(method, *args, &block)
  end

  def initialize
    @crop = CROPS.first
    @m3u_dir = 'm3u'
    go_to_default_channel
    reset_sleep_timer
  end

  def configure(opts = {})
    @m3u_dir = opts[:m3u_dir] if opts[:m3u_dir]
  end

  def start
    url = "http://127.0.0.1:1337/channel/current.m3u"
    `DISPLAY=:0 /usr/bin/cvlc --fullscreen --no-osd --loop --one-instance --extraintf rc --rc-host localhost:2222 '#{url}'`
  end

  def reload
    socket = TCPSocket.new('localhost', 2222)
    socket.puts "clear"
    socket.puts "add http://127.0.0.1:1337/channel/current.m3u"
    socket.close
  end

  def reset_sleep_timer
    @sleep_thread.kill if @sleep_thread
    @sleep_thread = Thread.new do
      sleep(SLEEP_TIMER)
      puts '--> Going to sleep'
      TVM3U.go_to_default_channel
      reload
    end
  end

  def toggle_crop
    next_crop_index = (CROPS.index(@crop) + 1) % CROPS.length
    @crop = CROPS[next_crop_index]

    socket = TCPSocket.new('localhost', 2222)
    socket.puts "crop #{@crop}"
    socket.close
  end
  
  def current_m3u
    return default_channel_m3u if @current_channel == :default

    items = get_m3u_items(@current_channel).to_a
    total_time = total_time(items)
    current_time = time_elapsed % total_time

    item_start_time = current_time
    item_end_time = 0
    found_index = 0

    items.each.with_index do |item, i|
      if item_start_time < item[:duration]
        found_index = i
        item_start_time = item_start_time.to_i
        item_end_time = (item[:duration] - item_start_time).to_i
        break
      else
        item_start_time -= item[:duration]
      end
    end

    lines = [
      # header
      "#EXTM3U\n",

      # first episode (start part-way through)
      "#EXTVLCOPT:start-time=#{item_start_time}\n",
      items[found_index..-1].map { |item| item[:text] },

      # rest of episodes
      items[0...(found_index - 1)].map { |item| item[:text] },

      # first episode again (end part-way through)
      "#EXTVLCOPT:end-time=#{item_end_time}\n",
      items[found_index][:text],
    ].flatten.join
  end

  def go_to_default_channel
    @current_channel = :default
  end

  def advance_channel(diff)
    channels = Dir.glob(File.join(@m3u_dir, '*.m3u'))
    current_channel_index = channels.index(@current_channel)
    next_channel_index = 0
  
    if current_channel_index
      next_channel_index = (current_channel_index + diff) % channels.length
    end
  
    @current_channel = channels[next_channel_index]
  end

  private

  def default_channel_m3u
    contents = """
    #EXTM3U
    #EXTINF:10,SMPTE Color Bars
    file://#{File.expand_path('color-bars.png')}
    """
  end

  def time_elapsed
    Time.now.to_i
  end

  def get_m3u_items(path)
    # Chunk up file into lines every time we see #EXTINF, and extract the length
    items = []
    acc = ''

    File.open(path).each_line do |line|
      next if line.start_with?('#EXTM3U')

      if line.start_with?('#EXTINF:')
        if acc != ''
          item = { text: acc, duration: item_duration(acc) }
          items << item
        end

        acc = line
      else
        acc += line
      end
    end

    # Add the last item
    if acc != ''
      item = { text: acc, duration: item_duration(acc) }
      items << item
    end

    items
  end

  def item_duration(str)
    str.match(/#EXTINF:(\d+),/)[1].to_i
  end

  def total_time(items)
    items.map { |item| item[:duration] }.sum
  end
end