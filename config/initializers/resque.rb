require 'resque'
require 'resque_jobs'
Resque.redis.namespace = "resque:"+Rails.configuration.database_configuration[Rails.env]['database']
