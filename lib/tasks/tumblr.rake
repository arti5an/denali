namespace :tumblr do
  task :export => [:environment] do
    last = Entry.find(2541)
    entries = Entry.where('status = ? AND published_at > ?', 'published', last.published_at).tagged_with(["Wyoming", "Montana", "Mount Rainier National Park"], any: true).order('published_at ASC')
    entries.each do |e|
      puts "Exporting entry #{e.id}: #{e.plain_title}"
      TumblrWorker.new.perform(e.id, true)
      sleep 1
    end
  end
end
