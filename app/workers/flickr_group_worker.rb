class FlickrGroupWorker < ApplicationWorker
  sidekiq_options queue: 'low'

  def perform(photo_id, group_url)
    return if !Rails.env.production?
    begin
      flickr = FlickRaw::Flickr.new ENV['FLICKR_CONSUMER_KEY'], ENV['FLICKR_CONSUMER_SECRET']
      flickr.access_token = ENV['FLICKR_ACCESS_TOKEN']
      flickr.access_secret = ENV['FLICKR_ACCESS_TOKEN_SECRET']
      slug = group_url.split('/').last
      group = if /\d+@N\d+/.match? slug
        flickr.groups.getInfo(group_id: slug)
      else
        flickr.groups.getInfo(group_path_alias: slug)
      end
      flickr.groups.pools.add(photo_id: photo_id, group_id: group['nsid'])
    rescue FlickRaw::FailedResponse => e
      logger.error "[Flickr] Photo #{photo_id} failed to add to group #{group_url}: #{e}"
    end
  end
end
