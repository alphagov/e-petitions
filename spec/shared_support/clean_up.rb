at_exit do
  puts "Cleaning up..."
  [
    'log/threshold_response*'
  ].each do |file|
    path = File.join(Rails.root, file)
    FileUtils.rm_r(Dir.glob(path))
  end
  puts "Done."
end