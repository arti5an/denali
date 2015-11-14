namespace :queue do
  desc 'Publish the first entry in the queue'
  task :publish => [:environment] do
    entry = Entry.queued.first
    if entry.nil?
      puts 'There are no posts in the queue.'
    elsif entry.publish
      IftttJob.perform_later(entry)
      BufferJob.perform_later(entry, 'twitter') if entry.post_to_twitter
      BufferJob.perform_later(entry, 'facebook') if entry.post_to_facebook
      TumblrJob.perform_later(entry) if entry.post_to_tumblr
      FlickrJob.perform_later(entry) if entry.post_to_flickr && entry.is_photo?
      puts "Entry \"#{entry.title}\" published successfully."
    else
      puts 'Queued entry failed to publish.'
    end
  end
end
