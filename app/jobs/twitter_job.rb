require 'open-uri'
class TwitterJob < ActiveJob::Base
  include ActionView::Helpers::TextHelper
  include Addressable

  queue_as :default

  def perform(entry)
    twitter = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['twitter_consumer_key']
      config.consumer_secret     = ENV['twitter_consumer_secret']
      config.access_token        = ENV['twitter_access_token']
      config.access_token_secret = ENV['twitter_access_token_secret']
    end
    tweet = build_tweet(entry, twitter.configuration.short_url_length_https, twitter.configuration.characters_reserved_per_media)
    if entry.is_photo?
      width = twitter.configuration.photo_sizes[:large].width
      twitter.update_with_media(tweet, open(entry.photos.first.url(width)))
    else
      twitter.update(tweet)
    end
  end

  def build_tweet(entry, short_url_length, media_length)
    max_length = entry.is_text? ? 137 - short_url_length : 137 - short_url_length - media_length
    "#{truncate(entry.formatted_title, length: max_length, omission: '… ')}#{permalink_url(entry)}"
  end
end
