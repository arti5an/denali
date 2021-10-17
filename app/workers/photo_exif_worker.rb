require 'exifr/jpeg'
require 'open-uri'
class PhotoExifWorker < ApplicationWorker

  def perform(photo_id)
    photo = Photo.find(photo_id)
    raise UnprocessedPhotoError unless photo.processed?

    original = URI.open(photo.image.url)
    exif = EXIFR::JPEG.new(original)
    if exif.present? && exif.exif?
      camera_make = exif.make&.encode('UTF-8')&.strip
      camera_model = exif.model&.encode('UTF-8')&.strip
      camera_name = "#{camera_make} #{camera_model}".strip
      photo.camera = Camera.create_with(display_name: camera_name, make: camera_make, model: camera_model, is_phone: camera_model.match?(/iphone/i)).find_or_create_by(slug: camera_name.parameterize) if camera_make.present? && camera_model.present?

      lens_make = exif.lens_make&.encode('UTF-8')&.strip || camera_make
      lens_model = exif.lens_model&.encode('UTF-8')&.strip
      lens_name = "#{lens_make} #{lens_model}".strip
      photo.lens = Lens.create_with(display_name: lens_name, make: lens_make, model: lens_model).find_or_create_by(slug: lens_name.parameterize) if lens_make.present? && lens_model.present?

      photo.iso = exif.iso_speed_ratings
      photo.taken_at = exif.date_time
      photo.exposure = exif.exposure_time
      photo.f_number = exif&.f_number&.to_f
      photo.focal_length = exif&.focal_length&.to_i
      if exif.gps.present?
        photo.longitude = exif.gps.longitude
        photo.latitude = exif.gps.latitude
      end
      if exif.user_comment.present?
        comment_array = exif.user_comment.encode('UTF-8').split(/(\n)+/).select{ |c| c =~ /^film/i }
        film_make = comment_array.select{ |c| c =~ /^film make/i }&.first&.gsub(/^film make:/i, '')&.strip
        film_type = comment_array.select{ |c| c =~ /^film type/i }&.first&.gsub(/^film type:/i, '')&.strip
        film_type = "#{film_type&.gsub(%r{#{exif.iso_speed_ratings}}i, '').strip} #{exif.iso_speed_ratings}" if exif.iso_speed_ratings.present?
        film_name = "#{film_make} #{film_type}"
        photo.film = Film.create_with(display_name: film_name, make: film_make, model: film_type).find_or_create_by(slug: film_name.parameterize) if film_make.present? && film_type.present?
      end
      if exif.image_description.present? && photo.alt_text.blank?
        photo.alt_text = exif.image_description.encode('UTF-8')
      end
    end
    photo.save!
  end
end
