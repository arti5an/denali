namespace :queue do
  desc 'Publish the first entry in the queue'
  task :publish => [:environment] do
    entry = Entry.queued.first
    if entry.nil?
      puts 'There are no posts in the queue.'
    elsif entry.publish
      puts "Entry \"#{entry.title}\" published successfully."
    else
      puts 'Queued entry failed to publish.'
    end
  end

  task :fix => [:environment] do
    Entry.queued.each_with_index do |entry, index|
      entry.position = index + 1
      entry.save
    end
  end
end
