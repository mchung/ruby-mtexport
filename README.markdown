# Want to move your [TypePad.com][6] or [MovableType][5] powered blog somewhere else? 

## [Export][1] Your Data:

Follow the [instructions][1] at SixApart to export/backup your [MovableType][5] content.  After you've archived your data (mtexport.dump) you can use mtexport to parse entries and images, convert to [Jekyll][2] (recommended), or convert to [WordPress][3] (don't do it).

## Parse Your [MovableType][5] Data:

    file = File.read("mtexport.dump")
    mt = MtexportParser.new(file)
    mt.parse
    mt.print_summary

## Generate a List of Images:

    file = File.read("mtexport.dump")
    mt = MtexportParser.new(file)
    mt.parse
    mt.print_fullsize_images

## Convert to [Jekyll's][2] [Markdown][4] Data Structure:

    file = File.read("mtexport.dump")
    mt = MtexportParser.new(file)
    mt.parse
    jekyll = MtToJekyll.new
    jekyll.output_dir = "_posts"
    mt.each_blog_post do |entry|
        jekyll.to_markdown(entry)
        puts "Done processing: #{entry[:title]}"
    end

## Convert to [Jekyll][2] from the Command Line (`_posts`):

    ruby mt_to_jekyll.rb <path-to-export>

## Convert to [WordPress'][3] RSS Data Structure:

    file = File.read("mtexport.dump")
    mt = MtexportParser.new(file)
    mt.parse
    wordpress = MtToWordPress.new
    wordpress.base_url = 'http://foo.com'
    wordpress.mt_url = 'http://foo.typepad.com'
    wordpress.image_dir = '/images'
    wordpress.print_rss(mt)

## Convert to [WordPress][3] RSS from the Command Line:

    ruby mt_to_wordpress.rb <path-to-export> <blog-url> <typepad-url> <image-dir>


  [1]: http://www.sixapart.com/movabletype/docs/mtimport
  [2]: http://jekyllrb.com
  [3]: http://wordpress.org
  [4]: http://daringfireball.net/projects/markdown/
  [5]: http://www.sixapart.com/movabletype/
  [6]: http://www.typepad.com
