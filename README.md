# Welsh Parliament Petitions

This is the code base for the Welsh Parliament's petitions service (https://petition.parliament.wales).

## Setup

We recommend using [Docker Desktop][1] to get setup quickly. If you'd prefer not to use Docker then you'll need Ruby (2.4+), Node (10+), PostgreSQL (9.6+) and Memcached (1.4+) installed.

### Create the databases

```
docker-compose run --rm web rake db:setup
```

### Create an admin user

```
docker-compose run --rm web rake wpets:add_sysadmin_user
```

### Fetch the country list

```
docker-compose run --rm web rails runner 'FetchCountryRegisterJob.perform_now'
```

### Enable signature counting

```
docker-compose run --rm web rails runner 'Site.enable_signature_counts!(interval: 10)'
```

### Start the services

```
docker-compose up
```

Once the services have started you can access the [front end][2], [back end][3] and any [emails sent][4].

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

# Deisebau Senedd Cymru

Dyma sylfaen cod gwasanaeth deisebau Senedd Cymru (https://deiseb.senedd.cymru).

## Setup

Rydym yn argymell defnyddio [Docker Desktop] [1] i gael setup yn gyflym. Os byddai'n well gennych beidio â defnyddio Docker yna bydd angen Ruby (2.4+), Node (10+), PostgreSQL (9.6+) a Memcached (1.4+) arnoch chi wedi'u gosod.

### Creu’r cronfeydd data

```
docker-compose run --rm web rake db:setup
```

### Creu defnyddiwr gweinyddol

```
docker-compose run --rm web rake wpets:add_sysadmin_user
```

### Chwiliwch am y rhestr gwledydd

```
docker-compose run --rm web rails runner 'FetchCountryRegisterJob.perform_now'
```

### Galluogi cyfrif llofnod

```
docker-compose run --rm web rails runner 'Site.enable_signature_counts!(interval: 10)'
```

### Dechreuwch y gwasanaethau

```
docker-compose up
```

Ar ôl i'r gwasanaethau gychwyn gallwch gyrchu'r [pen blaen][2], [pen ôl][3] ac unrhyw [e-byst a anfonwyd][4].

## Tests

Gallwch chi redeg y gyfres brawf lawn gan ddefnyddio'r gorchymyn canlynol:

```
docker-compose run --rm web rake
```

Gellir rhedeg specs unigol gan ddefnyddio'r gorchymyn canlynol:

```
docker-compose run --rm web rspec spec/models/parliament_spec.rb
```

Yn yr un modd, gellir rhedeg nodweddion ciwcymbr unigol gan ddefnyddio'r gorchymyn canlynol:

```
docker-compose run --rm web cucumber features/suzie_views_a_petition.feature
```

[1]: https://www.docker.com/products/docker-desktop
[2]: http://localhost:3000/
[3]: http://localhost:3000/admin
[4]: http://localhost:1080/
