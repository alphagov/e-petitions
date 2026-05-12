namespace :lighthouse do
  desc "Run lighthouse specs in headless mode"
  task ci: "environment" do
    at_exit {
      ActiveRecord::FixtureSet.reset_cache
      Rake::Task["assets:clobber"].invoke
    }

    Rake::Task["db:migrate"].invoke
    Rake::Task["assets:precompile"].invoke

    fixtures_path = "#{::Rails.root}/spec/fixtures"
    fixtures = %w[pages rejection_reasons]

    ActiveRecord::FixtureSet.create_fixtures(fixtures_path, fixtures)

    if !system("npm run lighthouse:ci")
      exit 1
    end
  end
end
