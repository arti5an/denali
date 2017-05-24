class EntriesController < ApplicationController
  include TagList

  before_action :check_if_user_has_visited, only: [:index, :tagged, :show, :preview]
  before_action :set_request_format, only: [:index, :tagged, :show]
  before_action :load_tags, only: [:tagged, :tag_feed]
  before_action :set_max_age, only: [:index, :tagged]
  before_action :set_entry_max_age, only: [:show, :preview]

  def index
    if stale?(@photoblog, public: true)
      @page = (params[:page] || 1).to_i
      @count = (params[:count] || @photoblog.posts_per_page).to_i
      @entries = @photoblog.entries.includes(:photos).published.photo_entries.page(@page).per(@count)
      raise ActiveRecord::RecordNotFound if @entries.empty?
      begin
        respond_to do |format|
          format.html
          format.json
        end
      rescue ActionController::UnknownFormat
        if @page == 1
          redirect_to(entries_path, status: 301)
        else
          redirect_to(entries_path(page: @page), status: 301)
        end
      end
    end
  end

  def tagged
    if stale?(@photoblog, public: true)
      @page = (params[:page] || 1).to_i
      @count = (params[:count] || @photoblog.posts_per_page).to_i
      @entries = @photoblog.entries.includes(:photos).published.photo_entries.tagged_with(@tag_list, any: true).page(@page).per(@count)
      raise ActiveRecord::RecordNotFound if @tags.empty? || @entries.empty?
      begin
        respond_to do |format|
          format.html
          format.json
        end
      rescue ActionController::UnknownFormat
        if @page == 1
          redirect_to(tag_path(@tag_slug), status: 301)
        else
          redirect_to(tag_path(tag: @tag_slug, page: @page), status: 301)
        end
      end
    end
  end

  def show
    if stale?(@photoblog, public: true)
      @entry = @photoblog.entries.includes(:photos, :user, :blog).published.find(params[:id])
      begin
        respond_to do |format|
          format.html {
            redirect_to(@entry.permalink_url, status: 301) unless params_match(@entry, params)
          }
          format.json
        end
      rescue ActionController::UnknownFormat
        redirect_to(@entry.permalink_url, status: 301)
      end
    end
  end

  def feed
    if stale?(@photoblog, public: true)
      @page = (params[:page] || 1).to_i
      @entries = @photoblog.entries.includes(:photos).published.photo_entries.page(@page).per(@photoblog.posts_per_page)
      raise ActiveRecord::RecordNotFound if @entries.empty?
      begin
        respond_to do |format|
          format.atom
          format.json
        end
      rescue ActionController::UnknownFormat
        render text: 'Not found', status: 404
      end
    end
  end

  def tag_feed
    if stale?(@photoblog, public: true)
      @page = (params[:page] || 1).to_i
      @entries = @photoblog.entries.includes(:photos).published.photo_entries.tagged_with(@tag_list, any: true).page(@page).per(@photoblog.posts_per_page)
      raise ActiveRecord::RecordNotFound if @tags.empty? || @entries.empty?
      begin
        respond_to do |format|
          format.atom
          format.json
        end
      rescue ActionController::UnknownFormat
        render text: 'Not found', status: 404
      end
    end
  end

  def preview
    request.format = 'html'
    if stale?(@photoblog, public: true)
      @entry = @photoblog.entries.includes(:photos, :user, :blog).where(preview_hash: params[:preview_hash]).limit(1).first
      raise ActiveRecord::RecordNotFound if @entry.nil?
      respond_to do |format|
        format.html {
          if @entry.is_published?
            redirect_to @entry.permalink_url
          else
            render 'entries/show'
          end
        }
      end
    end
  end

  def tumblr
    expires_in 1.year, public: true
    @entry = @photoblog.entries.published.where(tumblr_id: params[:tumblr_id]).order('published_at ASC').first
    raise ActiveRecord::RecordNotFound if @entry.nil?
    if stale?(@entry, public: true)
      respond_to do |format|
        format.html {
          redirect_to @entry.permalink_url, status: 301
        }
      end
    end
  end

  def sitemap
    expires_in 24.hours, public: true
    if stale?(@photoblog, public: true)
      @entries = @photoblog.entries.published
      render format: 'xml'
    end
  end

  private
  def params_match(entry, params)
    entry_date = entry.published_at
    year = entry_date.strftime('%Y')
    month = entry_date.strftime('%-m')
    day = entry_date.strftime('%-d')
    slug = entry.slug

    year == params[:year] &&
    month == params[:month] &&
    day == params[:day] &&
    slug == params[:slug]
  end

  def set_request_format
    request.format = 'json' if request.headers['Content-Type'].try(:downcase) == 'application/vnd.api+json'
  end
end
