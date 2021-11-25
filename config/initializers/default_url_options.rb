if Rails.env.production? || Rails.env.staging?
  host = if ENV['HEROKU_PARENT_APP_NAME'].present?
    "#{ENV['HEROKU_APP_NAME']}.herokuapp.com"
  else
    ENV['domain']
  end
  protocol = Rails.application.config.force_ssl ? 'https' : 'http'
  Rails.application.routes.default_url_options.merge!(
    host: host,
    protocol: protocol,
  )
else Rails.env.development?
  Rails.application.routes.default_url_options.merge!(
    host: 'localhost:3000',
    protocol: 'http',
  )
end
