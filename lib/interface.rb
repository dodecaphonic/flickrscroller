class Interface < Gtk::Window
  Parameters = Struct.new(:aspect, :resize_to, :compare_to, :child, :add, :remove, :pack_method)
  Sizes = { :tiny => 45, :small => 90, :medium => 120, :large => 200 }
  VERSION = "0.1"
  
  def initialize(orientation=:horizontal, size=:small)
    super()
    @fixed = Gtk::Fixed.new
    @infolabel = Gtk::Label.new
    @picturebox = nil
    @interactionbox = Gtk::Table.new 2, 2
    @waitingbox = Gtk::HBox.new false, 10
    @tagbox = Gtk::Entry.new
    @scroller = nil
    @scroller_thr = nil
    @scrolling = false
    @combined_size = 0
    @width = 0
    @height = 0
    @orientation = orientation
    @used_size = size
    @ag = Gtk::AccelGroup.new
    @params = Parameters.new

    create_visuals
    connect_signals
    add_accelerators
    set_parameters
  end

  private
  def create_visuals
    # Hints window manager that this window should stick through
    # desktops.
    stick

    # Creates image container according to Scrollr's orientation
    case @orientation
    when :horizontal then 
        @picturebox = Gtk::HBox.new false, 1
        @width, @height = Gdk.screen_width, Sizes[@used_size]
        #@width = 1280 if @width > 1280
    when :vertical   then 
      @picturebox = Gtk::VBox.new false, 1
      @width, @height = Sizes[@used_size], Gdk.screen_height
    end

    # Creates "Interaction Box", for lack of a better name. It holds
    # a label, an entry box and a little button.
    title = Gtk::Label.new
    title.markup = "<span size='small' foreground='white'>Scrollr v#{VERSION}</span>"
    @interactionbox.attach title, 0, 2, 0, 1
    @interactionbox.attach @tagbox, 0, 1, 1, 2

    # Sets our little spinner's animation and builds infobox
    animation = Gdk::PixbufAnimation.new 'data/spinner.gif'
    spinner = Gtk::Image.new
    spinner.pixbuf_animation = animation
    @waitingbox.pack_start spinner
    @waitingbox.pack_start @infolabel

    # Sets main window's properties
    set_decorated false
    set_size_request @width, @height
    resize @width, @height
    set_title "Scrollr"

    # Adds all widgets to the main window and performs adjustments
    add @fixed
    @fixed.put @picturebox, 0, 0
    @picturebox.set_size_request @width, @height
    @fixed.put @interactionbox, 20, @height - 60
    @fixed.put @waitingbox, 20, @height - 60
    
    #set color
    set_app_paintable true
    #@window.modify_bg(Gtk::StateType.new(0), Gdk::Color.parse('black'))
  end

  # Adds keyboard accelerators. +@ag+ is defined as an instance variable
  # to deal with the garbage collecting of blocks defining accelerator
  # behavior.
  def add_accelerators
    @ag.connect(Gdk::Keyval::GDK_T, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE)  do
        unless @interactionbox.visible?
            @interactionbox.visible = true
            @tagbox.grab_focus
        else
            @interactionbox.visible = false
        end
    end
    @ag.connect(Gdk::Keyval::GDK_Q, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE)  do 
        @scroller_thr.kill if @scroller_thr
        Gtk.main_quit
    end
    add_accel_group @ag
  end

  # Connects signals for all desired widget behaviors.
  def connect_signals
    add_events Gdk::Event::BUTTON_PRESS_MASK 
    signal_connect('button_press_event') do |w, e|
        begin_move_drag e.button, e.x_root, e.y_root, e.time
    end
    signal_connect('delete-event') { Gtk.main_quit }
    @tagbox.signal_connect('activate') do |w|
      if @scroller_thr
        @scroller_thr.kill
        @picturebox.children.each { |child| @picturebox.remove child }
        @combined_size = 0
        GC.start
      end

      @scroller = Scroller.new w.text.strip, :small
      @scroller.add_observer self
      Thread.abort_on_exception = true
      @scroller_thr = Thread.new(@scroller) { |scroller| @scroller.scroll }
      @interactionbox.visible = false
      @waitingbox.visible = true
      @infolabel.text = ''
    end
    signal_connect('enter_notify_event') { |w, e| grab_focus }
    signal_connect('expose-event') do |w, e|
      cr = w.window.create_cairo_context
      cr.set_operator Cairo::OPERATOR_SOURCE
      cr.set_source_rgba 0.0, 0.0, 0.0, 0.85
      cr.paint
      false
      # cr
    end

    signal_connect('screen-changed') { |w, e| screen_changed w }
  end    

  def screen_changed(w)
    screen = w.screen
    cmap = screen.rgba_colormap
    w.set_colormap cmap
  end

  def start_scrolling
    @infolabel.text = ''
    @scrolling = true
    @waitingbox.visible = false
  end

  def set_parameters
    case @orientation
    when :horizontal then
      @params.aspect = :height 
      @params.resize_to = @height
      @params.compare_to = @width
      @params.child = Proc.new  { @picturebox.children.first }
      @params.add = Proc.new { |i| i.send(:width) }
      @params.remove = Proc.new { |child| child.get_size_request()[0] }
      @params.pack_method = Proc.new { |child| @picturebox.pack_start child, false, false }
    when :vertical   then
      @params.aspect = :width
      @params.resize_to = @width
      @params.compare_to = @height
      @params.child = Proc.new { @picturebox.children.first }
      @params.add = Proc.new { |i| i.send(:height) }
      @params.remove = Proc.new { |child| child.get_size_request()[1] }
      @params.pack_method = Proc.new { |child| @picturebox.pack_start child, false, false }
    end
  end

  public
  def show
    screen_changed self
    show_all
    @waitingbox.visible = false
    Gtk.main
  end

  def update(args)
    if args[:event] == :new_image
      start_scrolling unless @scrolling
      image = args[:data]
          
      image.resize! @params.aspect => @params.resize_to
      @combined_size += @params.add.call(image)
      if @combined_size > @params.compare_to
        while @combined_size > @params.compare_to
          i = @params.child.call
          unless i.nil?
              @combined_size -= @params.remove.call(i)
              @picturebox.remove(i)
          end
        end
      end

      i = ImageWidget.new image
      i.show

      @params.pack_method.call i
    elsif args[:event] == :caching
      text = "#{@scroller.images_cached} image#{@scroller.images_cached > 1 ? 's' : ''} cached"
      @infolabel.markup = "<span foreground='white' size='x-small'>#{text}</span>"
    elsif args[:event] == :the_end
      while @picturebox.children

      end
    end
  end
end
