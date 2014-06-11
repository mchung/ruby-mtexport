class MtToWordPress

  RSS_ATTRIBUTES = {:version => '2.0',
                 'xmlns:excerpt' => 'http://purl.org/rss/1.0/modules/content/',
                 'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
                     'xmlns:wfw' => "http://wellformedweb.org/CommentAPI/",
                      'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                      'xmlns:wp' => "http://wordpress.org/export/1.2/"}

  def base_url=(url)
    @base_url = url
  end

  def mt_url=(url)
    @mt_url = url
  end
  
  def image_dir=(dir)
    @image_dir = dir
  end

  def print_rss(mt)
    puts build_rss(mt)
  end

  def build_rss(mt)
    # inspired/adapted from: https://github.com/chloerei/blog_converter/
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.rss(RSS_ATTRIBUTES) do
        xml.channel do
          xml['wp'].wxr_version   '1.2'
          mt.each_blog_post do |entry|
            xml.item do
              parsedDate = DateTime.strptime(entry[:date], "%m/%d/%Y %H:%M:%S %p")
              content = entry[:body]
              if entry[:extended_body]
                content = content + "\n<!--more-->\n"
                content = content + entry[:extended_body]
              end
              xml.title               entry[:title]
              xml.pubDate             parsedDate.rfc2822
              xml['dc'].creator       {|xml| xml.cdata entry[:author]}
              xml['content'].encoded  {|xml| xml.cdata normalize_html(content)}
              xml['excerpt'].encoded  {|xml| xml.cdata normalize_html(entry[:excerpt])}
              xml['wp'].post_date     parsedDate
              xml['wp'].post_type     'post'
              xml['wp'].status        'publish'
              if entry[:category]
                entry[:category].each do |cat|
                  nicename = cat.downcase.gsub(' ','-')
                  xml.category(:domain => 'category', :nicename => nicename) {|xml| xml.cdata cat}
                end
              end
            end
          end
        end
      end
    end
    builder.to_xml
  end

  def normalize_html(content) 
    haystack = Nokogiri::HTML(content)
    # remove onclick attributes
    if haystack.xpath('//@onclick')
      haystack.xpath('//@onclick').remove
    end
    # remove inline style attributes
    if haystack.xpath('//@style')
      haystack.xpath('//@style').remove
    end
    # look for custom url and typepad url references
    [@base_url,@mt_url].each do |url|
      # anchors
      haystack.css("a").each do |needle|
        if needle['href']
          # update relative image link references
          if needle['href'].include?(url+'/.a')
            needle['href'] = needle['href'].gsub(url+'/.a', @image_dir) + '.jpg'
          end
          # replace popup references with target attribute
          if needle['href'].include?('-popup')
            needle['href'] = needle['href'].gsub('-popup','')
            needle['target'] = '_new'
          end
        end
      end
      # images
      haystack.css("img").each do |needle|
        # update relative image source attributes
        if needle['src'].include?(url+'/.a')
          needle['src'] = needle['src'].gsub(url+'/.a', @image_dir) + '.jpg'
        end
      end
    end
    return haystack.css("body").inner_html
  end

end

if __FILE__ == $0
  require 'date'
  require 'nokogiri'
  require 'pp'
  raise "Usage: #{__FILE__} [mt_export] [base_url] [mt_url] [image_dir]" if ARGV.length < 4
  require File.dirname(__FILE__) + '/mtexport_parser'
  mt = MtexportParser.new(File.read(ARGV[0]))
  mt.parse
  wordpress = MtToWordPress.new
  wordpress.base_url = ARGV[1]
  wordpress.mt_url = ARGV[2]
  wordpress.image_dir = ARGV[3]
  wordpress.print_rss(mt)
end