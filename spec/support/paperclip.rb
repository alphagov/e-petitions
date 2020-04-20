require 'paperclip/matchers'
require 'fileutils'

module PaperclipHelpers
  def commons_image_fixture_path(filename)
    Rails.root.join('spec', 'fixtures', 'images', 'debate_outcome', filename)
  end

  def commons_default_image_url
    ActionController::Base.helpers.image_url('frontend/senedd-chamber.jpg')
  end

  def commons_image_file
    commons_image_fixture_path 'commons_image-2x.jpg'
  end

  def commons_image_file_too_small
    commons_image_fixture_path 'commons_image-too-small.jpg'
  end

  def commons_image_file_wrong_ratio
    commons_image_fixture_path 'commons_image-wrong-ratio.jpg'
  end
end

RSpec.configure do |config|
  config.include PaperclipHelpers
  config.include Paperclip::Shoulda::Matchers

  config.before(:suite) do
    FileUtils.mkdir_p "#{Rails.root}/public/test"
    Paperclip::Attachment.default_options[:url] = '/test/:class/:attachment/:id_partition/:style/:filename'
  end

  config.after(:suite) do
    FileUtils.rm_rf "#{Rails.root}/public/test"
    Paperclip::Attachment.default_options[:url] = '/system/:class/:attachment/:id_partition/:style/:filename'
  end
end
