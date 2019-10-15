class TwitterWorker < BufferWorker

  def perform(entry_id, now = false)
    entry = Entry.published.find(entry_id)
    max_length = 230 # 280 characters - 25 for the image url - 25 for the permalink url
    caption = entry.tweet_text.present? ? entry.tweet_text : entry.plain_title
    text = "#{truncate(caption.gsub(/\s+&\s+/, ' and '), length: max_length, omission: '…')} #{entry.permalink_url}"
    now = Rails.env.production? ? now : false
    if entry.is_photo?
      photos = entry.photos.to_a[0..4]
      opts = {
        text: text,
        media: media_hash(photos.shift, alt_text: true),
        now: now
      }
      opts[:extra_media] = photos.map { |p| media_hash(p, alt_text: true) } if photos.present?
      post_to_buffer('twitter', opts)
    else
      post_to_buffer('twitter', text: text, now: now)
    end
  end
end
