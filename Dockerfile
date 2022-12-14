ARG base_image=ghcr.io/alphagov/govuk-ruby-base:3.1.2
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:3.1.2

FROM $builder_image AS builder

ENV ASSETS_PREFIX=/assets/maslow

WORKDIR $APP_HOME
COPY Gemfile* .ruby-version ./
RUN bundle install
COPY . ./
RUN bundle exec rails assets:precompile && rm -fr log


FROM $base_image

ENV ASSETS_PREFIX=/assets/maslow \
    GOVUK_APP_NAME=maslow

WORKDIR $APP_HOME
COPY --from=builder $BUNDLE_PATH $BUNDLE_PATH/
COPY --from=builder $APP_HOME ./
USER app
CMD ["puma"]
