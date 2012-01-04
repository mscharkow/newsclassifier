require "bundler/vlad"

set :application, "nc3"
set :repository, "http://github.com/mscharkow/newsclassifier.git"

set :user, "deploy"
set :domain, "#{user}@newsclassifier.org"
set :deploy_to, "/home/deploy/apps/#{application}"
set :bundle_cmd, [ "source ~/.rvm/scripts/rvm",
                    "bundle"
                  ].join(" && ")

task :demo do
  set :domain,    "demo.newsclassifier.org"
  set :deploy_to, "/home/deploy/apps/nc3_demo"
end

task "vlad:deploy" => %w[
  vlad:update vlad:bundle:install vlad:start_app vlad:cleanup
]