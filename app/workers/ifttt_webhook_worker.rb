class IftttWebhookWorker < ApplicationWorker
  sidekiq_options queue: 'high'

  def perform(event, payload)
    return if !Rails.env.production? || ENV['ifttt_webhook_key'].blank? || event.blank? || payload.blank?
    url = "https://maker.ifttt.com/trigger/#{event}/with/key/#{ENV['ifttt_webhook_key']}"
    response = HTTParty.post(url, body: payload.to_json, headers: { 'Content-Type': 'application/json' })
  end
end
