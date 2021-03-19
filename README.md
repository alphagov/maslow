# Maslow

Maslow is a tool to create and manage user needs.


## Technical documentation

This is a Ruby on Rails app, and should follow [our Rails app conventions][].

You can use the [GOV.UK Docker environment][] to run the application and its tests with all the necessary dependencies.  Follow [the usage instructions][] to get started.

**Use GOV.UK Docker to run any commands that follow.**

[our Rails app conventions]: https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html
[GOV.UK Docker environment]: https://github.com/alphagov/govuk-docker
[the usage instructions]: https://github.com/alphagov/govuk-docker#usage

### Testing

The default `rake` task runs all the tests and records code coverage:

```sh
bundle exec rake
```

After running the tests, the `coverage/` folder contains the generated report.

### User accounts

Authentication is provided by the [GDS-SSO][] gem.  In the production environment an instance of [Signon][] must be running in order to sign in.

In the development environment, the mock strategy is used by default.  This removes the requirement for authentication, instead returning the first user in the database as the current user.  This user is defined in `db/seeds.rb`.

[GDS-SSO]: https://github.com/alphagov/gds-sso
[Signon]: https://github.com/alphagov/signon


## Licence

[MIT License](LICENCE)
