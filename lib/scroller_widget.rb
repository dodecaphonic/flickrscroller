class ScrollerWidget < Gtk::DrawingArea
    def initialize
        @cache = []
        @paused = false
        @orientation = :horizontal
        self.signal_connect("expose-event") { |w| expose w }
    end

    def add_image(image)
        @cache << image
    end

    def pause
        @paused = true
    end

    def resume
        @paused = false
    end

    private
    def expose(w)
        return if cache.size < 3
        return if @paused

        width, height = self.get_size_request
        if width > height
            @orientation = :horizontal
        else
            @orientation = :vertical
        end
    end
end
