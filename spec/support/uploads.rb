require 'rack/test/uploaded_file'

Rack::Test::UploadedFile.class_eval do
  # redefine inspect to the original filename for nicer test output
  def inspect
    original_filename
  end
end
