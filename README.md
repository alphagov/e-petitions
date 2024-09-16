# Petitions

This is the code base for the [UK Government and Parliament's petitions service][1].

## Setup

We recommend using [Docker Desktop][2] to get setup quickly. If you'd prefer not to use Docker then you'll need Ruby (3.2+), Node (20+) and PostgreSQL (16+) installed.

### Create the databases

```
docker compose run --rm web rake db:setup
```

### Load the country list

```
docker compose run --rm web rake epets:countries:load
```

### Fetch the regions list

```
docker compose run --rm web rails runner 'FetchRegionsJob.perform_now'
```

### Fetch the constituencies list

```
docker compose run --rm web rails runner 'FetchConstituenciesJob.perform_now'
```

### Fetch the department list

```
docker compose run --rm web rails runner 'FetchDepartmentsJob.perform_now'
```

### Enable signature counting

```
docker compose run --rm web rails runner 'Site.enable_signature_counts!(interval: 10)'
```

### Start the services

```
docker compose up
```

Once the services have started you can access the [front end][3], [back end][4] and any [emails sent][5].

## Tests

Before running any tests the database needs to be prepared:

```
docker compose run --rm web rake db:test:prepare
```

You can run the full test suite using following command:

```
docker compose run --rm web rake
```

Individual specs can be run using the following command:

```
docker compose run --rm web rspec spec/models/parliament_spec.rb
```

Similarly, individual cucumber features can be run using the following command:

```
docker compose run --rm web cucumber features/suzie_views_a_petition.feature
```

## Moderation Portal SSO

The moderation portal is authenticated using the [OmniAuth][6] gem and implements
a light wrapper around strategies so that multiple configurations of a strategy can be
supported, e.g. two or more SAML identity providers.

The `config/sso.yml` has a configuration of the `Developer` strategy for local development
which should not be used in production. The test configuration in the file shows how a
typical SAML IdP would be configured.

There are four key attributes that need to be returned in the OmniAuth `auth_info` hash,
these being `first_name`, `last_name`, `email` and `groups`. The `email` attribute acts
as the uid for the user and the `groups` attribute controls what role they get assigned.

The configuration attributes are:

- **name**

  This is a required attribute and must be unique. It also must be suitable for use
  in a url as it forms part of the callback url for OmniAuth.

- **strategy**

  This is the OmniAuth strategy to use as the parent class for the identity provider.

- **domains**

  The list of email domains to use with this identity provider, e.g.

  ``` yaml
  domains:
    - "example.com"
  ```

- **roles**

  Controls the mapping of the `groups` attribute to the assigned role, e.g.
  
  ``` yaml
  roles:
    sysadmin:
      - "System Administrators"
    moderator:
      - "Petition Moderators"
    reviewer:
      - "Petition Reviewers"
  ```
  
  The default for any of the three roles is an empty set so if an identity provider is
  only being used for one of the roles then there's no need to configure the others.

- **config**

  This is the configuration that is passed to the OmniAuth strategy and should
  be a hash of the documented options supported by the strategy.

[1]: https://petition.parliament.uk
[2]: https://www.docker.com/products/docker-desktop
[3]: http://localhost:3000/
[4]: http://localhost:3000/admin
[5]: http://localhost:1080/
[6]: https://github.com/omniauth/omniauth
