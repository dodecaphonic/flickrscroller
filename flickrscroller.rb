#!/usr/bin/env ruby

require 'lib/flickrscroller'
orientation, size = nil, nil
path = File.join(ENV['HOME'], '.scrollrrc')
unless File.exist? path
  orientation, size = :horizontal, :medium
  File.open(path, 'w').write "horizontal\nmedium"
else
  orientation, size = File.open(path).read.split.map {|x| x.to_sym}
end

fs = Interface.new orientation, size
fs.show
