desc "Run rubocop with similar params to CI"
task "lint" do
  sh "bundle exec rubocop --format clang app bin config Gemfile lib test"
end
