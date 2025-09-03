require 'rake'

RSpec.configure do |config|
  config.before(:suite) do
    Rails.application.load_tasks

    Rake::Task["css:build"].invoke
    Rake::Task["javascript:build"].invoke
  end
end
