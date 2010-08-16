require 'date'

class Scroller
  include Observable
  APIKEY = nil
  SHAREDSECRET = nil
  CACHESIZE = 5

  def initialize(criteria, size)
    @size = size
    @criteria = criteria
    @cache = []

    unless APIKEY.nil? and SHAREDSECRET.nil?
      FlickRaw.api_key = APIKEY
      FlickRaw.shared_secret = SHAREDSECRET
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
  end

  # Returns number of images cached
  def images_cached
    @cache.size
  end

  private
  def add_photo(photo)
    begin
      sizes = flickr.photos.getSizes :photo_id => photo.id
      tags  = flickr.tags.getListPhoto(:photo_id => photo.id).tags
      wanted = @size.to_s.capitalize
      original = sizes.find { |s| s.label == wanted }
      url = original.source.gsub('\\', '').gsub(/\s+/, '')

      image = open(url).read
      flickr_url = "http://www.flickr.com/photos/#{photo.owner}/#{photo.id}"
      image = Image.new(image, :photo_id => photo.id,
                        :user => photo.owner, :url => flickr_url,
                        :title => photo.title, :tags => tags)
      @cache << image

      changed
      if @cache.size > CACHESIZE
        notify_observers :event => :new_image, :data => @cache.first
        @cache.delete @cache.first
      else
        notify_observers :event => :caching, :data => nil
      end
    rescue
    end
  end
end
