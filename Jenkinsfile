#!/usr/bin/env groovy

library("govuk@default-branch")

node("mongodb-2.4") {
  govuk.buildProject(defaultBranch: "main")
}
