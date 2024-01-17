require 'json'

class AppState
  attr_reader :epoch

  def self.instance
    @@instance ||= AppState.new
  end

  def initialize
    @current_channel = generate_default_channel_m3u
  end

  def current_m3u
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

  def next_m3u(diff)
    channels = Dir.glob('m3u/*.m3u')
    current_channel_index = channels.index(@current_channel)
    next_channel_index = 0

    if current_channel_index
      next_channel_index = (current_channel_index + diff) % channels.length
    end

    @current_channel = channels[next_channel_index]
    current_m3u
  end

  private

  def generate_default_channel_m3u
    contents = """
    #EXTM3U
    #EXTINF:10,SMPTE Color Bars
    file://#{File.expand_path('color-bars.png')}
    """

    File.write('m3u/000_default.m3u', contents)
    'm3u/000_default.m3u'
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