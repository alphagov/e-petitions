namespace :jasmine do
  desc "Run Jasmine tests in headless mode"
  task ci: "assets:precompile" do
    at_exit {
      Rake::Task["assets:clobber"].invoke
    }

    if !system("npx jasmine-browser-runner runSpecs")
      exit 1
    end
  end
end
