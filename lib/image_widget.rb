class ImageWidget < Gtk::DrawingArea
  TextSize = { :tiny => 10, :small => 12, :normal => 14, :large => 18 }

  def initialize(image, params=nil)
    super()
    @image = image
    @show_text = true
    @text_size = :small

    if params
      params.each do |k, v|
        @show_text = v if k == :show_text
        @text_size = v if k == :text_size
      end
    end
    connect_signals
  end

  private
  def connect_signals
    set_events(Gdk::Event::ENTER_NOTIFY_MASK |
               Gdk::Event::LEAVE_NOTIFY_MASK |
               Gdk::Event::BUTTON_PRESS_MASK)
    signal_connect("enter_notify_event") do |x, y, data|
      cr = window.create_cairo_context
      cr.set_line_width 5.0
      cr.rectangle 0, 0, @image.width, @image.height
      cr.set_source_rgba 0.0, 0.0, 0.0, 0.6
      cr.fill_preserve
      cr.set_source_rgb 1.0, 1.0, 1.0
      cr.stroke

      if @show_text and @image.title
        pa = cr.create_pango_layout
        pa.width = @image.width - 10
        title = @image.title
        if (first = title.split.first).nil?
          first = ""
        end
        pa.text = first
        fd = Pango::FontDescription.new
        fd.family = "DejaVu Sans"
        fd.absolute_size = TextSize[@text_size] * Pango::SCALE
        fd.weight = Pango::FontDescription::WEIGHT_BOLD
        pa.set_font_description fd
        cr.move_to 8, 5
        cr.set_source_rgba 1.0, 1.0, 1.0, 0.8
        cr.show_pango_layout pa
        fd = Pango::FontDescription.new
        fd.family = "DejaVu Sans"
        fd.absolute_size = TextSize[:tiny] * Pango::SCALE
        fd.weight = Pango::FontDescription::WEIGHT_NORMAL
        pa.set_font_description fd
        last_y = 10
        @image.tags.each_with_index do |t, i|
          break if i > 2
          y = last_y + 15
          pa.text = t.to_s
          cr.move_to 12, y
          cr.show_pango_layout pa
          last_y = y
        end
      end
    end

    signal_connect("leave_notify_event") do |x, y, data|
      window.invalidate Gdk::Rectangle.new(0, 0, @image.width, @image.height), true
    end

    signal_connect("expose_event") { |w, e| expose(w, e) }
    signal_connect("button_press_event") do |w, e|
      Kernel.system "firefox", "-new-window", @image.url
      false
    end
  end

  def expose(w, e)
    set_size_request @image.width, @image.height
    l = Gdk::PixbufLoader.new
    l.last_write @image.buffer
    window.draw_pixbuf nil, l.pixbuf, 0, 0, 0, 0, @image.width, @image.height, Gdk::RGB::DITHER_NORMAL, 0, 0
  end
end
