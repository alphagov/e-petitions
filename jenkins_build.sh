
rvm use 1.8.7@epets
bundle install --without development --frozen

# Clean up left over stuff from previous builds (logs etc...)
git clean -fd

cp -f config/database_jenkins.yml config/database.yml
RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
RAILS_ENV=test bundle exec rake ci
