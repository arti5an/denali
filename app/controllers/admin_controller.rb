class AdminController < ApplicationController
  layout 'admin'
  before_action :block_cloudfront
  before_action :redirect_heroku
  before_action :no_cache
  before_action :require_login
  skip_before_action :domain_redirect
  skip_before_action :is_repeat_visit?
  helper_method :is_admin?

  def default_url_options
    if Rails.env.production? || Rails.env.staging?
      { host: ENV['ADMIN_DOMAIN'] }
    else
      Rails.application.routes.default_url_options
    end
  end

  def index
    redirect_to admin_entries_path
  end

  def is_admin?
    true
  end

  def set_referrer_policy
    response.headers['Referrer-Policy'] = 'same-origin'
  end
end
