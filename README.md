# Maslow

Maslow is a tool to create and manage needs. It's a Rails app which is
part of the GOV.UK Publishing Platform.

## Dependencies

- Ruby
- Bundler
- NodeJS
- Yarn
- A running instance of the [Publishing API](https://github.com/alphagov/publishing-api)

## User accounts

Authentication is provided by the [GDS-SSO](https://github.com/alphagov/gds-sso) gem, and in the production environment an instance of [Signon](https://github.com/alphagov/signon) must be running in order to sign in.

In the development environment, the mock strategy is used by default. This removes the requirement for authentication, instead returning the first user in the database as the current user. For this to work, a user must exist - there's a user defined in `db/seeds.rb`.

## Licence

[MIT License](LICENCE)
