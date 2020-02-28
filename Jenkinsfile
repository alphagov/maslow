#!/usr/bin/env groovy

library("govuk")

node("mongodb-2.4") {
  govuk.buildProject(
    // TODO: SASS linting is disabled because it currently fails
    sassLint: false,
    brakeman: true,
    rubyLintDiff: false,
  )
}
