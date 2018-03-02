#!/usr/bin/env groovy

library("govuk")

REPOSITORY = 'maslow'

node {

  try {
    stage("Checkout") {
      checkout scm
    }

    stage('Clean') {
      govuk.cleanupGit()
    }

    stage('Env') {
      govuk.setEnvar('RAILS_ENV', 'test')
    }

    stage('Bundle') {
      govuk.bundleApp()
    }

    stage('Lint') {
      govuk.rubyLinter()
    }

    stage("Build") {
      govuk.runRakeTask('db:mongoid:drop')
      sh "bundle exec rake"
    }

    stage("Result") {
      govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
      govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
    notifyEveryUnstableBuild: true,
    recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
    sendToIndividuals: true])
    throw e
  }

}
