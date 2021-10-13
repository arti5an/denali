require 'test_helper'

class EntryTest < ActiveSupport::TestCase

  test 'should not save entry without title' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(body: 'Test', blog: blog, user: user)
    assert_not entry.save
  end

  test 'should set slug before saving' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    title = 'This should be in my title. This should not.'
    entry = Entry.new(title: title, body: 'Whatever.', blog: blog, user: user)
    entry.save
    assert_equal 'this-should-be-in-my-title', entry.slug
  end

  test 'should set preview hash before saving' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    title = 'This is my title'
    entry = Entry.new(title: title, body: 'Whatever.', blog: blog, user: user)
    entry.save
    assert_not_nil entry.preview_hash
  end

  test 'should be draft' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'draft', blog: blog, user: user, post_to_twitter: true)
    entry.save
    assert entry.is_draft?
    assert_equal 0, TwitterWorker.jobs.size
    assert_equal 0, FacebookWorker.jobs.size
    assert_equal 0, FlickrWorker.jobs.size
    assert_equal 0, InstagramWorker.jobs.size
    assert_equal 0, WebhookWorker.jobs.size
  end

  test 'should be queued' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user, post_to_twitter: true)
    entry.save
    assert entry.is_queued?
    assert_equal 0, TwitterWorker.jobs.size
    assert_equal 0, FacebookWorker.jobs.size
    assert_equal 0, FlickrWorker.jobs.size
    assert_equal 0, InstagramWorker.jobs.size
    assert_equal 0, WebhookWorker.jobs.size
  end

  test 'should be published' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'published', blog: blog, user: user, post_to_twitter: true, post_to_facebook: false, post_to_flickr: false, post_to_instagram: false)
    entry.save
    assert entry.is_published?
    assert_equal 1, TwitterWorker.jobs.size
    assert_equal 0, FacebookWorker.jobs.size
    assert_equal 0, FlickrWorker.jobs.size
    assert_equal 0, InstagramWorker.jobs.size
    assert_equal 2, WebhookWorker.jobs.size
  end

  test 'should change drafts to published' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'draft', blog: blog, user: user)
    entry.save
    entry.publish
    assert entry.is_published?
  end

  test 'should change queued to published' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save
    entry.publish
    assert entry.is_published?
  end

  test 'should change drafts to queued' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'draft', blog: blog, user: user, post_to_twitter: true)
    entry.save
    entry.queue
    assert entry.is_queued?
  end

  test 'should change queued to draft' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user, post_to_twitter: true)
    entry.save
    entry.draft
    assert entry.is_draft?
  end

  test 'should not change published to queued' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'published', blog: blog, user: user)
    entry.save
    entry.queue
    assert entry.is_published?
  end

  test 'should not change published to draft' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'published', blog: blog, user: user)
    entry.save
    entry.draft
    assert entry.is_published?
  end

  test 'publish should set published_at & modified_at' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save
    assert_nil entry.published_at
    assert_nil entry.modified_at
    entry.publish
    assert_not_nil entry.published_at
    assert_not_nil entry.modified_at
  end

  test 'publish should enqueue jobs' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user, post_to_twitter: true, post_to_facebook: false, post_to_flickr: false, post_to_instagram: false)
    entry.save
    assert_equal 0, TwitterWorker.jobs.size
    assert_equal 0, FacebookWorker.jobs.size
    assert_equal 0, FlickrWorker.jobs.size
    assert_equal 0, InstagramWorker.jobs.size
    assert_equal 0, WebhookWorker.jobs.size
    entry.publish
    assert_equal 1, TwitterWorker.jobs.size
    assert_equal 0, FacebookWorker.jobs.size
    assert_equal 0, FlickrWorker.jobs.size
    assert_equal 0, InstagramWorker.jobs.size
    assert_equal 2, WebhookWorker.jobs.size
  end

  test 'changing drafts to queued should not enqueue jobs' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'draft', blog: blog, user: user, post_to_twitter: true)
    entry.save
    entry.queue
    assert_equal 0, TwitterWorker.jobs.size
    assert_equal 0, FacebookWorker.jobs.size
    assert_equal 0, FlickrWorker.jobs.size
    assert_equal 0, InstagramWorker.jobs.size
    assert_equal 0, WebhookWorker.jobs.size
  end

  test 'changing queued to draft should not enqueue jobs' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user, post_to_twitter: true)
    entry.save
    entry.draft
    assert_equal 0, TwitterWorker.jobs.size
    assert_equal 0, FacebookWorker.jobs.size
    assert_equal 0, FlickrWorker.jobs.size
    assert_equal 0, InstagramWorker.jobs.size
    assert_equal 0, WebhookWorker.jobs.size
  end

  test 'queuing should set a position' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save
    assert_not_nil entry.position
  end

  test 'publishing a queued post should clear the position' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save
    assert_not_nil entry.position
    entry.publish
    assert_nil entry.position
  end

  test 'draft should not set published_at' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save
    entry.draft
    assert_nil entry.published_at
  end

  test 'queue should not set published_at' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'draft', blog: blog, user: user)
    entry.save
    entry.queue
    assert_nil entry.published_at
  end

  test 'publish should not set position' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save
    entry.publish
    assert_nil entry.position
  end

  test 'draft should not set position' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save
    entry.draft
    assert_nil entry.position
  end

  test 'queue should set position' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'draft', blog: blog, user: user)
    entry.save
    entry.queue
    assert_not_nil entry.position
  end

  test 'published_at should not change' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save
    entry.publish
    published_at = entry.published_at
    entry.publish
    assert_equal published_at, entry.published_at
  end

  test 'entry formatting should work' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry = Entry.new(title: 'This is the *title* you\'re looking for & stuff', body: 'This is the *body* you\'re looking for & stuff.', status: 'queued', blog: blog, user: user)
    entry.save
    assert_equal 'This is the title you’re looking for & stuff', entry.plain_title
    assert_equal "<p>This is the <em>body</em> you&rsquo;re looking for &amp; stuff.</p>\n", entry.formatted_body
    assert_equal 'This is the body you’re looking for & stuff.', entry.plain_body
  end

  test 'entry positioning should work' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)
    entry_1 = entries(:panda)

    entry_2 = Entry.new(title: 'test 1', status: 'queued', blog: blog, user: user)
    entry_2.save
    entry_3 = Entry.new(title: 'test 2', status: 'queued', blog: blog, user: user)
    entry_3.save

    entry_1.move_lower
    assert_equal 2, entry_1.position

    entry_1.move_higher
    assert_equal 1, entry_1.position

    entry_1.move_to_bottom
    assert_equal 3, entry_1.position

    entry_1.move_to_top
    assert_equal 1, entry_1.position
  end

  test 'instagram hashtags' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)

    tag = TagCustomization.new(instagram_hashtags: 'awildlifehashtag', blog: blog)
    tag.tag_list.add('tag a', 'tag b')
    tag.save!
    tag.reload

    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save!

    assert_empty entry.instagram_hashtags

    entry.add_tags('tag a')
    entry.reload
    assert_empty entry.instagram_hashtags

    entry.add_tags('tag b')
    entry.reload
    assert_not_empty entry.instagram_hashtags
  end

  test 'flickr groups' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)

    tag = TagCustomization.new(flickr_groups: 'https://flickr.com/whatever/', blog: blog)
    tag.tag_list.add('tag c', 'tag d')
    tag.save!
    tag.reload

    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save!
    assert_empty entry.flickr_groups

    entry.add_tags('tag c')
    entry.reload
    assert_empty entry.flickr_groups

    entry.add_tags('tag d')
    entry.reload
    assert_not_empty entry.flickr_groups
  end

  test 'flickr albums' do
    user = users(:guille)
    blog = blogs(:allencompassingtrip)

    tag = TagCustomization.new(flickr_albums: 'https://flickr.com/whatever/', blog: blog)
    tag.tag_list.add('tag c', 'tag d')
    tag.save!
    tag.reload

    entry = Entry.new(title: 'Title', body: 'Body.', status: 'queued', blog: blog, user: user)
    entry.save!
    assert_empty entry.flickr_albums

    entry.add_tags('tag c')
    entry.reload
    assert_empty entry.flickr_albums

    entry.add_tags('tag d')
    entry.reload
    assert_not_empty entry.flickr_albums
  end

  test 'adding tags' do
    entry = entries(:panda)
    entry.tag_list = 'Panda'
    entry.location_list = 'Washington'
    entry.equipment_list = 'Nikon'
    entry.style_list = 'Black & White'
    entry.save!
    entry.reload

    entry.add_tags('Panda, Washington, Mammal')
    assert entry.tag_list.include?('Panda')
    assert entry.location_list.include?('Washington')
    assert entry.style_list.include?('Black & White')

    assert entry.tag_list.include?('Mammal')
    assert !entry.tag_list.include?('Washington')
  end

  test 'locations set tags' do
    entry = entries(:panda)
    entry.tag_list = 'Foo'
    entry.save!
    entry.reload

    assert entry.tag_list.include? 'Foo'
    assert_not entry.tag_list.include? 'National Parks'
    assert_not entry.tag_list.include? 'National Monuments'

    entry.tag_list = 'Bar National Park'
    entry.save!
    entry.update_tags
    entry.reload

    assert entry.tag_list.include? 'Bar National Park'
    assert entry.tag_list.include? 'National Parks'
    assert_not entry.tag_list.include? 'National Monuments'

    entry.tag_list = 'Baz National Monument'
    entry.save!
    entry.update_tags
    entry.reload

    assert entry.tag_list.include? 'Baz National Monument'
    assert_not entry.tag_list.include? 'National Parks'
    assert entry.tag_list.include? 'National Monuments'

    entry.tag_list = 'Foo'
    entry.save!
    entry.update_tags
    entry.reload

    assert entry.tag_list.include? 'Foo'
    assert_not entry.tag_list.include? 'National Parks'
    assert_not entry.tag_list.include? 'National Monuments'
  end

  test 'checking if the queue has published today' do
    assert_equal 0, Entry.published_today.count
    entry = entries(:panda)
    entry.publish
    assert_equal 1, Entry.published_today.count
  end

  test 'find by url should return the correct entry' do
    entry = entries(:peppers)
    assert_equal entry, Entry.find_by_url(url: entry.permalink_url)
  end

  test 'find by url should 404 invalid urls' do
    assert_raises ActiveRecord::RecordNotFound do
      Entry.find_by_url(url: 'foo')
    end
  end

  test 'territories are rendered correctly' do
    entry = entries(:peppers)
    assert entry.territories.blank?
    assert entry.formatted_territories.blank?

    entry = entries(:eastern)
    assert_equal "Shoshone-Bannock, Eastern Shoshone, and Cheyenne lands", entry.formatted_territories

    entry = entries(:panda)
    assert_equal "Shoshone-Bannock and Eastern Shoshone lands", entry.formatted_territories

    entry = entries(:franklin)
    assert_equal "Shoshone-Bannock land", entry.formatted_territories
  end
end
