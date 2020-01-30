# Welsh Parliament Petitions

This is the code base for the Welsh Parliament's petitions service (https://petition.parliament.wales).

## Setup

We recommend using [Docker Desktop][1] to get setup quickly. If you'd prefer not to use Docker then you'll need Ruby (2.4+), Node (10+), PostgreSQL (9.6+) and Memcached (1.4+) installed.

### DNS

The application uses domains to differentiate between different aspects so you'll need to setup the following DNS records in your local `/etc/hosts` file:

```
127.0.0.1     welshpets.local
127.0.0.1     cymraegpets.local
127.0.0.1     moderatepets.local
```

If you don't want to edit your `/etc/hosts` file or you're on Windows then you can use a public wildcard DNS like `welshpets.lvh.me` and override the default domains using a `.env.local` file:

```
EPETITIONS_HOST_EN=welshpets.lvh.me
EPETITIONS_HOST_CY=cymraegpets.lvh.me
MODERATE_HOST=moderatepets.lvh.me
```

If you do this before running the app for the first time it will automatically pick these up, otherwise you'll need to use a PostgreSQL client to edit the `url_en`, `url_cy` and `moderate_url` columns on the record in the `sites` table.

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

### DNS

Mae'r rhaglen yn defnyddio parthau i wahaniaethu rhwng gwahanol agweddau felly bydd angen i chi osod y cofnodion DNS canlynol yn eich ffeil `/etc/hosts` leol:

```
127.0.0.1     welshpets.local
127.0.0.1     cymraegpets.local
127.0.0.1     moderatepets.local
```

Os nad ydych chi am olygu eich ffeil `/etc/hosts` neu os ydych chi ar Windows yna gallwch ddefnyddio DNS cerdyn gwyllt cyhoeddus fel `welshpets.lvh.me` a diystyru'r parthau diofyn gan ddefnyddio `.env.local` ffeil:

```
EPETITIONS_HOST_EN=welshpets.lvh.me
EPETITIONS_HOST_CY=cymraegpets.lvh.me
MODERATE_HOST=moderatepets.lvh.me
```

Os gwnewch hyn cyn rhedeg yr ap am y tro cyntaf, bydd yn codi'r rhain yn awtomatig, fel arall bydd angen i chi ddefnyddio cleient PostgreSQL i olygu'r colofnau `url_en`, `url_cy` a `moderate_url` ar y cofnod yn y bwrdd `safleoedd`.

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

## Profion

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
