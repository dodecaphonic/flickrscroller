#!/usr/bin/env ruby

require 'lib/flickrscroller'

if __FILE__ == $0
  options = {}

  path = File.join(ENV['HOME'], '.scrollr.conf')
  unless File.exist? path
    options.merge!({ 'orientation' => 'horizontal', 'size' => 'medium',
                    'position'    => 'bottom' })
    File.open(path, 'w') { |f| f << options.to_yaml }
  else
    options.merge! YAML.load(open(path))
  end

  fs = Interface.new options
  fs.show
end
