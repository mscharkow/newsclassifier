web: unicorn -c config/unicorn.rb
worker: rake environment resque:work QUEUE=*