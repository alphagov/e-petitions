e-petitions
===========

This is the code base for the UK Government's e-petitions service (http://epetitions.direct.gov.uk).  
We have open sourced the code for you to use under the terms of licence contained in this repository.

We hope you enjoy it!

A few things to know:

You will need `ruby 2.2.2`

You will need to set up the `database.yml`

For setting up a sysadmin user, run `rake epets:add_sysadmin_user` - the password must contain a mix of upper and lower case letters, numbers and special characters.

To start a solr instance, run `rake sunspot:solr:start`
To index the models, run `rake sunspot:reindex`
