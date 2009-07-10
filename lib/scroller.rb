require 'date'

class Scroller
  include Observable
  ApiKey = nil
  SharedSecret = nil
  CacheSize = 5

  def initialize(criteria, size)
    @size = size
    @criteria = criteria
    @cache = []

    unless ApiKey.nil? and SharedSecret.nil?
      FlickRaw.api_key = ApiKey
      FlickRaw.shared_secret = SharedSecret
    end
  end

  def scroll
    photos = nil
    unless @criteria.empty? or @criteria.nil?
      photos = flickr.photos.search :tags => @criteria
    else
      photos = flickr.interestingness.getList
    end
    photos.each { |photo| add_photo photo }
    p "the end"
  end

  # Returns number of images cached
  def images_cached
    @cache.size
  end

  private
  def add_photo(photo)
    sizes = flickr.photos.getSizes :photo_id => photo.id
    tags  = flickr.tags.getListPhoto(:photo_id => photo.id).tags
    wanted = @size.to_s.capitalize
    original = sizes.find { |s| s.label == wanted }
    url = original.source.gsub('\\', '').gsub(/\s+/, '')
    image = open(url).read

    if image
      flickr_url = "http://www.flickr.com/photos/#{photo.owner}/#{photo.id}"
      image = Image.new(image, :photo_id => photo.id,
                        :user => photo.owner, :url => flickr_url,
                        :title => photo.title, :tags => tags)
      @cache << image

      changed
      unless @cache.size < CacheSize
        notify_observers :event => :new_image, :data => @cache.first
        @cache.delete @cache.first
      else
        notify_observers :event => :caching, :data => nil
      end
    end
  end
end
