web: unicorn -p $PORT -c config/unicorn.rb
worker: rake environment resque:work QUEUE=*