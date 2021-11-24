class InstagramWorker < BufferWorker

  def perform(entry_id, text)
    return if !Rails.env.production?
    entry = Entry.published.find(entry_id)
    return if !entry.is_photo?
    raise UnprocessedPhotoError unless entry.photos_processed?

    photos = entry.photos.to_a[0..4]
    opts = {
      text: text,
      media: media_hash(photos.shift),
      now: true
    }

    if photos.present?
      opts[:extra_media] = photos.map { |p| media_hash(p) }
    else
      hashtags = entry.instagram_hashtags
      if hashtags.present?
        opts[:comment_enabled] = true
        opts[:comment_text] = hashtags
      end
    end

    updates = post_to_buffer('instagram', opts)
    updates.map { |u| InstagramCommentWorker.perform_in(1.minute, u) }
  end

  private
  def media_hash(photo)
    {
      photo: photo.instagram_url
    }
  end
end
