class WebhookWorker < ApplicationWorker
  sidekiq_options queue: 'high'

  def perform(webhook_id, entry_id)
    return if !Rails.env.production?

    webhook = Webhook.find(webhook_id)
    entry = Entry.published.find(entry_id)
    raise UnprocessedPhotoError if entry.is_photo? && !entry.photos_processed?
    payload = webhook.payload(entry)

    response = if payload.present?
      Typhoeus.post(webhook.url, body: payload.to_json, headers: { 'Content-Type': 'application/json' })
    else
      Typhoeus.post(webhook.url)
    end

    if response.code >= 400
      raise "Failed to send webhook: #{response.body}"
    end
  end
end
