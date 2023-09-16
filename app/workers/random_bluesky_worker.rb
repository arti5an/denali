
class RandomBlueskyWorker < ApplicationWorker
  def perform
    return if ENV['SHARE_RANDOM_PHOTOS'].blank?
    logger.info "[Queue] Attempting to share a random entry on Bluesky."
    photoblog = Blog.first
    return if photoblog.entries.published.first.published_at >= 2.days.ago || Entry.queued.count > 0
    entry = Entry.find(Entry.published.where('published_at >= ?', 4.years.ago).pluck(:id).sample)
    BlueskyWorker.perform_async(entry.id, entry.bluesky_caption) if entry.post_to_bluesky
  end
end