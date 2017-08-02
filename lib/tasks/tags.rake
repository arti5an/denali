namespace :tags do
  namespace :update do
    task :equipment => [:environment] do
      Entry.find_each do |e|
        tags = []
        e.photos.each do |p|
          tags << p.formatted_make
          tags << p.formatted_camera
          tags << p.formatted_film if p.film_make.present? && p.film_type.present?
        end
        puts "Adding the following tags to entry ##{e.id}: #{tags}"
        e.equipment_list.add(tags)
        e.save
      end
    end

    task :locations => [:environment] do
      if ENV['TAG'].present?
        Entry.tagged_with(ENV['TAG']).each do |e|
          ReverseGeocodeJob.perform_later(e) if e.show_in_map?
        end
      elsif ENV['ENTRY_ID'].present?
        e = Entry.find(ENV['ENTRY_ID'])
        ReverseGeocodeJob.perform_later(e) if e.present? && e.show_in_map?
      else
        Entry.find_each do |e|
          ReverseGeocodeJob.perform_later(e) if e.show_in_map?
        end
      end
    end

    task :keywords => [:environment] do
      if ENV['ENTRY_ID'].present?
        e = Entry.find(ENV['ENTRY_ID'])
        RekognitionJob.perform_later(e) if e.present?
      else
        Entry.find_each do |e|
          RekognitionJob.perform_later(e)
        end
      end
    end
  end

  namespace :clear do
    task :equipment => [:environment] do
      Entry.find_each do |e|
        puts "Removing equipment tags from entry ##{e.id}"
        e.equipment_list = []
        e.save
      end
    end

    task :locations => [:environment] do
      Entry.find_each do |e|
        puts "Removing location tags from entry ##{e.id}"
        e.location_list = []
        e.save
      end
    end

    task :keywords => [:environment] do
      Entry.find_each do |e|
        puts "Removing keyword tags from entry ##{e.id}"
        e.keyword_list = []
        e.save
      end
    end
  end

  task :cleanup => [:environment] do
    Entry.find_each do |e|
      e.tag_list.remove(e.equipment_list)
      e.tag_list.remove(e.location_list)
      e.save
    end
  end
end
