require 'resque'
require 'resque_jobs'
Resque.redis.namespace = "resque:nc3"
