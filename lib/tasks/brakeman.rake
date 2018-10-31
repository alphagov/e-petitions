namespace :brakeman do
  desc "Run brakeman checks and exit with an error code if there are any issues"
  task :check do
    unless system "brakeman -z --no-pager"
      exit 1
    end
  end
end
