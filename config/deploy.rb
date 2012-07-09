require "bundler/vlad"

set :application, "nc3"
set :repository, "http://github.com/mscharkow/newsclassifier.git"

set :user, "deploy"
set :domain, "#{user}@newsclassifier.org"
set :deploy_to, "/home/deploy/apps/#{application}"

set :rvm_cmd, "source ~/.rvm/scripts/rvm && rvm rvmrc trust #{deploy_to}/current && cd #{deploy_to}/current"

set :bundle_cmd, "#{rvm_cmd} && bundle"     
set :unicorn_command, "#{rvm_cmd} && bundle exec unicorn"


task :demo do
  set :application, "nc3_demo"
  set :deploy_to, "/home/deploy/apps/#{application}"
end



set :symlinks, {  'config/database.yml' => 'config/database.yml',
                  'config/config.yml' => 'config/config.yml'}


namespace :vlad do
  remote_task :start_unicorn do
    run "#{rvm_cmd} ; bundle exec unicorn_rails -c config/unicorn.rb -D"
  end
  
  remote_task :stop_unicorn do
    run "kill `cat #{deploy_to}/current/tmp/pids/unicorn.pid`"
  end  
  
  remote_task :start_resque do
    run "#{rvm_cmd};
    RAILS_ENV=production nohup bundle exec rake environment workers:start > log/workers.log 2>&1 &"
  end
  
  remote_task :stop_resque do
    run "kill `cat #{deploy_to}/current/tmp/pids/resque/*.pid`"
  end
end



task "vlad:deploy" => %w[
  vlad:update vlad:symlink vlad:bundle:install vlad:stop_unicorn vlad:start_unicorn vlad:stop_resque vlad:start_resque vlad:cleanup
]