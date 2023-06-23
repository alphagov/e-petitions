namespace :jasmine do
  desc "Run Jasmine tests in headless mode"
  task ci: "environment" do
    at_exit {
      Rake::Task["assets:clobber"].invoke
    }

    Sprockets::Rails::Task.new(Rails.application) do |t|
      t.log_level = :warn
    end

    Rake::Task["assets:precompile"].invoke

    if !system("npx jasmine-browser-runner runSpecs")
      exit 1
    end
  end
end
