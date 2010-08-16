FlickrScroller was written in 2007 to learn a little bit more about how alpha blending could be used in a GTK+ application, to work on my then rudimentary Ruby and to put nice images on my desktop and brighten my day.

Flickr's API has remained stable since, and FlickrScroller remains working. I've fixed a couple of things to cope with changes in [flickraw][1] just so you can run it and curse it for a while.

This is not code I'm proud of as is, but I still like pretty pictures. If you do too, check it out.

## Shortcuts

Ctrl + t — opens search box; "enter" brings things based on interestingness
Ctrl + q — quit

## Controlling the interface

You can create a file called *.scrollr.conf* on your home directory to tell FlickrScroller precisely how you want your interface to be displayed. Write a hash in YAML using the following:

 - orientation: (horizontal|vertical)
 - size: (tiny|small|medium|large)
 - side: (left|right|top|bottom)

If you don't provide a rc file, one will be created for you.

## Dependencies

 - RMagick
 - flickraw

TODO: add Gemfile to the mix, to help with setup.
 

[1]: http://github.com/hanklords/flickraw/tree/master