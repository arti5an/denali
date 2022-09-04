namespace :queue do
  desc 'Publish the first entry in the queue'
  task :publish => [:environment] do
    photoblog = Blog.first
    # Only attempt to publish a queued entry if another one hasn't been published in the last 10 minutes
    photoblog.publish_queued_entry! unless photoblog.entries.published.first.published_at >= 10.minutes.ago
  end
end
