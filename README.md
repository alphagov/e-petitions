# Petitions

This is the code base for the [UK Government and Parliament's petitions service][1].

## Setup

We recommend using [Docker Desktop][2] to get setup quickly. If you'd prefer not to use Docker then you'll need Ruby (2.4+), Node (10+), PostgreSQL (9.6+) and Memcached (1.4+) installed.

### Create the databases

```
docker-compose run --rm web rake db:setup
```

### Create an admin user

```
docker-compose run --rm web rake epets:add_sysadmin_user
```

### Fetch the country list

```
docker-compose run --rm web rails runner 'FetchCountryRegisterJob.perform_now'
```

### Fetch the constituencies list

```
docker-compose run --rm web rails runner 'FetchConstituenciesJob.perform_now'
```

### Enable signature counting

```
docker-compose run --rm web rails runner 'Site.enable_signature_counts!(interval: 10)'
```

### Start the services

```
docker-compose up
```

Once the services have started you can access the [front end][3], [back end][4] and any [emails sent][5].

## Tests

You can run the full test suite using following command:

```
docker-compose run --rm web rake
```

Individual specs can be run using the following command:

```
docker-compose run --rm web rspec spec/models/parliament_spec.rb
```

Similarly, individual cucumber features can be run using the following command:

```
docker-compose run --rm web cucumber features/suzie_views_a_petition.feature
```

[1]: https://petition.parliament.uk
[2]: https://www.docker.com/products/docker-desktop
[3]: http://localhost:3000/
[4]: http://localhost:3000/admin
[5]: http://localhost:1080/
