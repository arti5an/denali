namespace :tumblr do
  desc 'Update descriptions of Tumblr photos'
  task :update => :environment do

    tumblr = Tumblr::Client.new({
      consumer_key: ENV['TUMBLR_CONSUMER_KEY'],
      consumer_secret: ENV['TUMBLR_CONSUMER_SECRET'],
      oauth_token: ENV['TUMBLR_ACCESS_TOKEN'],
      oauth_token_secret: ENV['TUMBLR_ACCESS_TOKEN_SECRET']
    })

    total_posts = if ENV['POST_LIMIT'].present?
      ENV['POST_LIMIT'].to_i
    elsif ENV['UPDATE_QUEUE'].present?
      tumblr.blog_info(ENV['TUMBLR_DOMAIN'])['blog']['queue']
    else
      tumblr.blog_info(ENV['TUMBLR_DOMAIN'])['blog']['posts']
    end

    offset = 0
    limit = [20, total_posts].min
    updated = 0

    while offset <= total_posts
      puts "Fetching posts #{offset + 1}-#{offset + limit}, out of #{total_posts}"
      posts = if ENV['UPDATE_QUEUE'].present?
        tumblr.queue(ENV['TUMBLR_DOMAIN'], offset: offset, limit: limit)['posts']
      else
        tumblr.posts(ENV['TUMBLR_DOMAIN'], offset: offset, limit: limit, type: 'photo')['posts']
      end

      posts.each do |post|
        next if post['type'] != 'photo'
        
        tumblr_id = post['id']
        post_url = post['post_url']
        source_url = post['source_url']
        caption = post['caption']
        caption_url = Nokogiri::HTML.fragment(caption)&.css('a')&.select { |a| a.attr('href')&.match? ENV['DOMAIN'] }&.first&.attr('href')
        url = caption_url || source_url

        entry = begin
          Entry.find_by_url(url: url&.gsub('https://href.li/?', ''))
        rescue
          puts "  Can't update post #{post_url}, skipping."
          nil
        end

        next if entry.blank?

        seconds = 10 * updated
        TumblrUpdateWorker.perform_in(seconds.seconds, entry.id, tumblr_id)
        updated += 1
      end
      offset += limit
      sleep 1
    end
  end

end
