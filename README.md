Petitions
===========

This is the code base for the UK Government's petitions service (http://epetitions.direct.gov.uk).
We have open sourced the code for you to use under the terms of licence contained in this repository.

We hope you enjoy it!

A few things to know:

* You will need `ruby 2.2.2`
* You will need PostgreSQL and Memcached

### Setting your development environment

* clone the repo to your local machine
* install postgres. Easiest with homebrew using `$ brew install postgres`
	* If you like you can add postgres to your LaunchAgent. Follow instructions at end of console output
* Set up your dev and test databases
	* `$ psql postgres`
	* `# CREATE DATABASE epets_development;`
	* `# CREATE DATABASE epets_test;`
	* `# GRANT all privileges ON database epets_development TO epets;`
	* `# GRANT all privileges ON database epets_test TO epets;`
	* `# ALTER USER epets WITH PASSWORD 'replace_me';`
	* `# \q` to quit
* You will need to set up the `config/database.yml`. Copy what is in `config/database.example.yml` and add the password you used earlier for the `epets` postgres user
* `$ rake db:structure:load` - load the sql structure into your new databases
* `$ rails s` - boot the app

### Auxiliary

* If you want to seed your database with sample petitions, use `$ rake data:generate`
* If you want jobs (like emails) to be run, use `$ rake jobs:work`
* For setting up a sysadmin user
	* `rake epets:add_sysadmin_user` - to set up an admin user with email 'admin@example.com' and password 'Letmein1!'
	* go to `/admin` and log in. You will be asked to change your password. Remember, the password must contain a mix of upper and lower case letters, numbers and special characters.
