Petitions
===========

This is the code base for the UK Government's petitions service (https://petition.parliament.uk).
We have open sourced the code for you to use under the terms of licence contained in this repository.

We hope you enjoy it!

A few things to know:

* You will need `ruby 2.2.2`
* You will need PostgreSQL and Memcached

### Setting your development environment

* Clone the repo to your local machine
* Install PostgreSQL. Easiest with homebrew using `$ brew install postgres`
	* If you like you can add postgres to your LaunchAgent. Follow instructions at end of console output
* Install Memcached: `brew install memcached` - again, follow instructions at end of console output.
* Run `bundle install`
* Set up your dev and test databases
	* `$ psql postgres`
	* `# CREATE ROLE epets; ALTER ROLE epets WITH LOGIN;`
	* `# CREATE DATABASE epets_development;`
	* `# CREATE DATABASE epets_test;`
	* `# GRANT all privileges ON database epets_development TO epets;`
	* `# GRANT all privileges ON database epets_test TO epets;`
	* `# ALTER USER epets WITH PASSWORD 'replace_me';`
	* `# \q` to quit
* You will need to set up the `config/database.yml`. Add the password you used earlier for the `epets` postgres user, e.g. `username: epets` & `password: replace_me`
* `$ rake db:structure:load` - load the sql structure into your new databases
* `$ rails s` - boot the app

### Auxiliary

* If you want jobs (like emails) to be run, use `$ rake jobs:work`
* For setting up a sysadmin user
	* `rake epets:add_sysadmin_user` - to set up an admin user with email 'admin@example.com' and password 'Letmein1!'
	* go to `/admin` and log in. You will be asked to change your password. Remember, the password must contain a mix of upper and lower case letters, numbers and special characters.
