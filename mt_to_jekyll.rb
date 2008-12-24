class MtToJekyll

  def output_dir=(dir)
    @output_dir = dir
    Dir.mkdir(@output_dir) unless File.exist?(@output_dir)
  end

  def to_markdown(entry)
    set_permalink(entry)
    set_fmtdate(entry)
    set_markdown_filename(entry)
    emit_markdown(entry)
  end
  
  def to_markdown_filename(entry)
    set_permalink(entry)
    set_fmtdate(entry)
    set_markdown_filename(entry)
    entry[:filename]    
  end

  def set_permalink(entry)
    title = entry[:title]
    title = title.gsub(/\'/,"").gsub(/\W+/, '-').gsub(/_/, '-').gsub(/(^-+|-+$)/,'').downcase
    entry[:permalink] = title
  end

  def set_fmtdate(entry)
    fmtdate = Time.parse(entry[:date]).strftime("%d %b %Y")
    entry[:fmtdate] = fmtdate

    mm, dd, yy = entry[:date].split(" ")[0].split("/")
    entry[:date_year] = yy
    entry[:date_day] = dd
    entry[:date_month] = mm
    
    iso8601 = Time.parse(entry[:date]).iso8601
    entry[:isodate] = iso8601
  end

  def set_markdown_filename(entry)
    permalink = entry[:permalink]
    date = entry[:date] # 03/10/2008 07:47:00 AM
    filename = "#{entry[:date_year]}-#{entry[:date_month]}-#{entry[:date_day]}-#{permalink}.markdown"
    entry[:filename] = filename
  end

  def emit_markdown(entry)
    output = "#{@output_dir}/#{entry[:filename]}"
    File.open(output, "w+") do |file|
      file.puts("---")
      file.puts("layout: post")
      sanitize_title(entry)
      file.puts("title: #{entry[:title]}")
      file.puts("datetime: #{entry[:isodate]}")
      if entry[:category]
        file.puts("tags:")
        entry[:category].each do |tag|
          file.puts("- #{tag.downcase}")
        end
      end
      file.puts("---")
      file.puts("\n")
      file.puts(entry[:body])
    end
  end
  
  def sanitize_title(entry)
    entry[:title] = entry[:title].gsub(/:/, " -") # "Jan 1st: New Years" => "Jan 1st - New Years"
  end

end

if __FILE__ == $0
  raise "Usage: #{__FILE__} mtexport.dump" if ARGV.empty?
  require File.dirname(__FILE__) + '/mtexport_parser'
  require 'time'
  require 'pp'

  mt = MtexportParser.new(File.read(ARGV.first))
  mt.parse
  jekyll = MtToJekyll.new
  jekyll.output_dir = "_posts"
  mt.each_blog_post do |entry|
    jekyll.to_markdown(entry)
    puts "Done processing: #{entry[:title]}"
  end

  # mt.each_blog_post do |entry|
  #   if entry[:comment]
  #     pp [:title, jekyll.to_markdown_filename(entry), :comment, entry[:comment]]
  #   end
  # end
end