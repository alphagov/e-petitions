# Petitions

This is the code base for the [UK Government and Parliament's petitions service][1].

## Setup

We recommend using [Docker Desktop][2] to get setup quickly. If you'd prefer not to use
Docker then you'll need Ruby (3.2+), Node (20+) and PostgreSQL (16+) installed.

### Create the databases

```
bin/run rake db:setup
```

### Load the country list

```
bin/run rake epets:countries:load
```

### Fetch the regions list

```
bin/run rails runner 'FetchRegionsJob.perform_now'
```

### Fetch the constituencies list

```
bin/run rails runner 'FetchConstituenciesJob.perform_now'
```

### Fetch the department list

```
bin/run rails runner 'FetchDepartmentsJob.perform_now'
```

### Enable signature counting

```
bin/run rails runner 'Site.enable_signature_counts!(interval: 10)'
```

### Start the services

```
docker compose up
```

Once the services have started you can access the [front end][3], [back end][4] and any [emails sent][5].

## Tests

Before running any tests the database needs to be prepared:

```
bin/run rake db:test:prepare
```

You can run the full test suite using following command:

```
bin/run rake
```

Individual specs can be run using the following command:

```
bin/run rspec spec/models/parliament_spec.rb
```

Similarly, individual cucumber features can be run using the following command:

```
bin/run cucumber features/suzie_views_a_petition.feature
```

## Vector-based search

The search has an option to use vector embeddings which is disabled by default. If you want
to try this out we recommend using Docker and it's model runner feature to test locally - it's
configured to use the model mxbai-embed-large by default but this can be overridden by setting
environment variables in your `.env.local` file, e.g.

```
EMBEDDING_BACKEND=OpenAI
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_API_KEY=<your-api-key>
OPENAI_MODEL_ID=<your-preferred-model>
```

Alternatively you can use Amazon Bedrock to generate embeddings:

```
EMBEDDING_BACKEND=AmazonBedrock
AWS_REGION=eu-west-1
AWS_ACCESS_KEY_ID=<your-aws-access-key-id>
AWS_SECRET_ACCESS_KEY=<your-aws-secret-access-key>
```

If you have some petitions in your database already you can backfill them like this:

```
bin/run rails runner 'BackfillPetitionEmbeddingsJob.perform_now'
```

If you switch models/backends and you need to regenerate your embeddings then you'll
need to clear the cache and force the update like this:

```
bin/run rails runner 'BackfillPetitionEmbeddingsJob.perform_now(force: true, clear_cache: true)'
```

The embeddings use the pgvector halfvec type with 1024 dimensions so you'll need to use a
model that matches that or can be limited to that.

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
[3]: http://petitions.localhost:3000/
[4]: http://moderate.petitions.localhost:3000/admin
[5]: http://mailcatcher.localhost:1080/
[6]: https://github.com/omniauth/omniauth
