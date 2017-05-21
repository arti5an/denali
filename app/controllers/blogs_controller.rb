class BlogsController < ApplicationController
  before_action :set_entry_max_age

  def about
    fresh_when @photoblog, public: true
  end

  def offline
  end

  def manifest
    @icons = @photoblog.touch_icon.present? ? [128, 152, 144, 192].map { |size| { sizes: "#{size}x#{size}", type: 'image/png', src: @photoblog.touch_icon_url(w: size) } } : []
  end
end
