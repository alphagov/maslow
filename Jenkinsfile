#!/usr/bin/env groovy

library("govuk")

node {
  // Run against the MongoDB 3.6 Docker instance on GOV.UK CI
  govuk.setEnvar("MONGODB_URI", "mongodb://127.0.0.1:27036/maslow-test")

  govuk.buildProject()
}
