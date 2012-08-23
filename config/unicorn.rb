APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))
working_directory APP_ROOT
worker_processes 2
preload_app true
timeout 60

pid  APP_ROOT+ '/tmp/pids/unicorn.pid'
listen APP_ROOT + "/tmp/sockets/unicorn.sock"
stderr_path APP_ROOT + "/log/unicorn.stderr.log"
stdout_path APP_ROOT + "/log/unicorn.stdout.log"

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end