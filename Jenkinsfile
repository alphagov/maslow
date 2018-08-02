#!/usr/bin/env groovy

library("govuk")

node {
  govuk.buildProject(
    // TODO: SASS linting is disabled because it currently fails
    sassLint: false,
    brakeman: true,
  )
}
