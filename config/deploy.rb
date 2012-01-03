set :application, "nc3"
set :repository, "http://github.com/mscharkow/newsclassifier.git"

set :user, "deploy"
set :domain, "#{user}@newsclassifier.org"
set :deploy_to, "/home/deploy/apps/#{application}"


task :demo do
  set :domain,    "demo.newsclassifier.org"
  set :deploy_to, "/home/deploy/apps/nc3_demo"
end
