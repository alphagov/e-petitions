require 'rack/test/uploaded_file'

Rack::Test::UploadedFile.class_eval do
  # redefine inspect to the original filename for nicer test output
  def inspect
    original_filename
  end
end

RSpec.configure do |config|
  config.after(:suite) do
    storage_path = Rails.root.join("tmp", "storage", "*")

    Dir[storage_path].each do |path|
      FileUtils.rm_rf(path)
    end
  end
end
