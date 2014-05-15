Want to move your TypePad.com or MovableType-powered blog somewhere else? 

First, you'll need to [export][1] your blog and put it into a convenient data structure.  Here's how to do that:

    file = File.read("mtexport.dump")
    mt = MtexportParser.new(file)
    mt.parse
    mt.print_summary

You may want to generate a list of images so you can download them too:

    file = File.read("mtexport.dump")
    mt = MtexportParser.new(file)
    mt.parse
    mt.print_fullsize_images

And maybe you want to move it into Jekyll too? That's also easy:

    file = File.read("mtexport.dump")
    mt = MtexportParser.new(file)
    mt.parse
    jekyll = MtToJekyll.new
    jekyll.output_dir = "_posts"
    mt.each_blog_post do |entry|
        jekyll.to_markdown(entry)
        puts "Done processing: #{entry[:title]}"
    end
  
In fact, running this command will convert an export archive to Jekyll posts into `_posts`:

    ruby mt_to_jekyll.rb <path-to-export>

Viola!

  [1]: http://www.sixapart.com/movabletype/docs/mtimport
