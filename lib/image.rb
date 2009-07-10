class Image
  attr_reader :tags, :width, :height, :depth, :buffer, :url, :title

  def initialize(buffer, *args)
    args = args.shift
    @id   = args[:photo_id]
    @user = args[:user]
    @tags = args[:tags]
    @url  = args[:url]
    @title = args[:title]
    @image = Magick::Image.from_blob(buffer)[0]
    @buffer = @image.to_blob
    @width = @image.columns
    @height = @image.rows
    @depth = @image.depth
    @alpha = @image.matte
  end

  def has_alpha?
    @alpha
  end

  def resize(*args)
    params = args.shift
    width, height = params[:width], params[:height]
    new_image = nil

    if width and height.nil?
      height = @height * width / @width
    elsif height and width.nil?
      width = @width * height / @height
    end
    new_image = @image.resize width, height

    Image.new(@new_image.to_blob, :user => @user, :url => @url, 
              :tags => @tags, :photo_id => @id, :title => @title)
  end

  def resize!(*args)
    params = args.shift
    width, height = params[:width], params[:height]

    if width and height.nil?
      height = @height * width / @width
    elsif height and width.nil?
      width = @width * height / @height
    end
    @image.resize! width, height

    @width, @height = @image.columns, @image.rows
    @buffer = @image.to_blob
  end

  def to_s
    "#{@user} - #{@title} - #{@tags.join ', '}"
  end
end
