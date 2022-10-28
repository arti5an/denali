class TwitterWorker < ApplicationWorker
  sidekiq_options queue: 'high'

  def perform(entry_id, text)
    return if ENV['ENABLE_TWITTER'].blank?
    entry = Entry.published.find(entry_id)
    return if !entry.is_photo?
    raise UnprocessedPhotoError if entry.is_photo? && !entry.photos_have_dimensions?

    photos = entry.photos.to_a[0..4]

    opts = {
      text: text,
      photos: photos.map { |p| media_hash(p) }
    }

    if entry.show_location? && photos.first.has_location?
      opts[:latitude] = photos.first.latitude
      opts[:longitude] = photos.first.longitude
    end

    Twitter.new.tweet(opts)
  end

  private
  def media_hash(photo)
    {
      url: photo.twitter_url,
      alt_text: photo.alt_text
    }.compact
  end
end
