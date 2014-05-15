# http://www.sixapart.com/movabletype/docs/mtimport.html

#
# Parses file format exported by MovableType and Typepad blogs
#
class MtexportParser

  def initialize(content)
    @raw_data = content
    @processed = []
    @images = {'fullsize' => {}, 'inline' => {}, 'popup' => {}, 'external' => {}}
  end
  
  def parse
    @raw_data.split("--------\n").each do |entry|
      parse_blog_post(entry)
    end
  end

  def parse_blog_post(entry)
    items = entry.split("-----\n")
    blog_entry = {}
    parse_meta(blog_entry, items.first)
    items.shift
    parse_body(blog_entry, items)
    @processed << blog_entry
  end
  
  def each_blog_post(&block)
    @processed.each do |entry|
      yield entry
    end
  end

  def size
    @processed.size
  end

  def print_summary
    each_blog_post do |entry|
      puts "#{entry[:date]} - #{entry[:title]}"
    end
    puts "Found #{@processed.size} entries"
  end

  def print_all
    each_blog_post do |entry|
      pp entry
    end
    puts "Found #{@processed.size} entries"
  end

  def print_inline_images
    puts @images['inline'].keys.sort
    puts "Found #{@images['inline'].size} inline images"
  end

  def print_popup_images
    puts @images['popup'].keys.sort
    puts "Found #{@images['popup'].size} popup images"
  end

  def print_fullsize_images
    puts @images['fullsize'].keys.sort
    puts "Found #{@images['fullsize'].size} fullsize images"
  end

  def print_external_images
    puts @images['external'].keys.sort
    puts "Found #{@images['external'].size} external images"
  end

  def print_all_images 
    images = @images['fullsize']
    images = images.merge(@images['inline'])
    images = images.merge(@images['popup'])
    images = images.merge(@images['external'])
    puts images.keys.sort
    puts "Found #{images.size} images"
  end

  protected

  def parse_meta(blog_entry, meta_items)
    items = meta_items.split("\n")
    items.each do |meta|
      if !meta.empty?
        key, value = split(meta)
        key = d(key)
        if [:category].include?(key)
          blog_entry[key] ||= []
          blog_entry[key] << value
        else
          blog_entry[key] = value
        end
      end
    end
  end

  def parse_body(blog_entry, items)
    items.each do |item|
      key, value = split(item)

      next unless key && value # ignore blank key value

      # Automagically invoke the method named: process_#{name}
      # For example:
      #   key = "EXTENDED BODY" 
      #   name = "extended_body"
      #   method = "process_extended_body"

      name = "#{key.downcase.gsub(' ', '_')}"
      method = "process_#{name}"
      if self.respond_to?(method,true)
        self.send(method, blog_entry, name.to_sym, value) # invoke process_* method
        parse_images(value)
      else
        raise "Missing '#{method}' to handle label '#{key}'"
      end
    end
  end

  def parse_images(body)
    haystack = Nokogiri::HTML(body)
    # find onclick image links
    if haystack.css("a[onclick]").css("img")
      haystack.css("a[onclick]").css("img").each do |needle|
        register_image(needle['src'].to_s) if needle['src']
      end
    end
    # find linked images
    if haystack.css("a[class='asset-img-link']")
      haystack.css("a[class='asset-img-link']").each do |needle|
        register_image(needle['href'].to_s) if needle['href']
      end
    end
    # find inline images
    haystack.css("img").each do |needle|
      register_image(needle['href'].to_s) if needle['href']
    end
  end

  def register_image(image)
    # MT managed images
    if image.include?('.a')
      if image.include?('-')
        split_image = image.split('-')
        @images['fullsize'][split_image[0].to_s] = 1
        if split_image[1] == 'popup'
          @images['popup'][split_image[0].to_s] = 1
        else 
          @images['inline'][image] = 1
        end
      end
    else
      # External image references
      @images['external'][image] = 1
    end
  end

  def process_body(blog_entry, key_name, body)
    blog_entry[key_name] = body unless body.empty?
    # pp [:body, body]
  end

  def process_extended_body(blog_entry, key_name, extended_body)
    blog_entry[key_name] = extended_body unless extended_body.empty?
    # pp [:extended_body, extended_body]
  end

  def process_excerpt(blog_entry, key_name, excerpt)
    blog_entry[key_name] = excerpt unless excerpt.empty?
    # pp [:excerpt, excerpt]
  end

  def process_keywords(blog_entry, key_name, keywords)
    blog_entry[key_name] = keywords unless keywords.empty?
    # pp [:keywords, keywords]
  end

  # A Comment entry is a String that looks like this:
  #  "COMMENT:
  #  AUTHOR: Bar
  #  DATE: 02/01/2002 04:02:07 AM
  #  IP: 205.66.1.32
  #  EMAIL: me@bar.com
  #  This is the body of
  #  another comment. It goes
  #  up to here.
  #  "
  def process_comment(blog_entry, key_name, comment)
    blog_entry[key_name] ||= []
    if !comment.empty?
      blog_entry[key_name] << parse_list_with_comments(comment)
    end
    # pp [:comment, comment]
  end

  # A Ping entry is a String that looks like this:
  #   "PING:
  #   TITLE: My Entry
  #   URL: http://www.foo.com/old/2002/08/
  #   IP: 206.22.1.53
  #   BLOG NAME: My Weblog
  #   DATE: 08/05/2002 16:09:12
  #   This is the start of my
  #   entry, and here it...
  #   "
  def process_ping(blog_entry, key_name, ping)
    blog_entry[key_name] ||= []
    if !ping.empty?
      blog_entry[key_name] << parse_list_with_comments(ping)
    end
  end

  # PINGs and COMMENTs have a implied comments
  def parse_list_with_comments(data_list)
    list_results = {:comment => ""}
    pairs = data_list.split("\n")
    pairs.each do |en|
      k, v = split(en)
      if k && v
        list_results[d(k)] = v
      else
        list_results[:comment] << "#{en} "
      end
    end
    list_results
  end

  def split(meta)
    index = meta.index(":") # Find the first colon only
    if index
      key = meta[0..index-1]
      value = meta[index+1..meta.size].strip
      [key, value]
    end
  end

  def d(key)
    key.downcase.gsub(/ /, "").to_sym
  end

end

if __FILE__ == $0
  require 'pp'
  require 'nokogiri'
  raise "#{__FILE__} file.dump" unless ARGV.size > 0
  mt = MtexportParser.new(File.read(ARGV.first))
  mt.parse
  mt.print_summary
  # mt.print_all
  mt.print_fullsize_images
end
