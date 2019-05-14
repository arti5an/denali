class InstagramCommentWorker < ApplicationWorker
  sidekiq_options queue: 'low'

  def perform(update_id)
    return if ENV['buffer_access_token'].blank?
    response = HTTParty.get("https://api.bufferapp.com/1/updates/#{update_id}.json?access_token=#{ENV['buffer_access_token']}")
    update = JSON.parse(response.body)
    if update['status'] == 'sent' && update['comment_enabled']
      if update.dig('comment_state', 'success')
        logger.info "[Instagram] First comment posted for update #{update_id}"
      else
        logger.error "[Instagram] First comment failed for update #{update_id}: #{update.dig('comment_state', 'error')}"
        payload = {
          value1: update['text'],
          value2: update['service_link'],
          value3: update['media']['picture']
        }
        IftttWebhookWorker.perform_async('instagram-comment-failed', payload)
      end
    end
  end
end
