desc "Run linting"
task lint: :environment do
  sh "bundle exec rubocop --format clang"
end
