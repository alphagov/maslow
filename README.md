# Maslow

Maslow is a tool to create and manage needs. It's a Rails app which is
part of the GOV.UK Publishing Platform.

## Dependencies

- Ruby
- Bundler
- The Ruby Gems listed in the Gemfile
- A running instance of the [Publishing API](https://github.com/alphagov/publishing-api)

## Getting started

The bootstrap script should get you up and running in the development environment. It runs Bundler and creates a stub user in the database.

    ./script/bootstrap
    bundle exec unicorn -p 3001

### GDS development

If you're using the development VM, you should run the app from the `development` repository using Bowler and Foreman. The Need API will automatically be started alongside Maslow.

    cd development/
    bowl maslow

From your host machine, you should be able to access the app at <http://maslow.dev.gov.uk/>.

## User accounts

Authentication is provided by the [GDS-SSO](https://github.com/alphagov/gds-sso) gem, and in the production environment an instance of [Signon](https://github.com/alphagov/signonotron2) must be running in order to sign in.

In the development environment, the mock strategy is used by default. This removes the requirement for authentication, instead returning the first user in the database as the current user. For this to work, a user must exist - there's a user defined in `db/seeds.rb` which will be created with the bootstrap script.
