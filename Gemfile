source 'http://rubygems.org'

gem 'rails', '~> 3.1.3'
gem 'sqlite3'
gem 'mysql2'


group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

# Use unicorn as the web server
gem 'unicorn'

# Deploy with Capistrano
gem 'vlad-git'
gem 'vlad-unicorn'


group :test do
  gem 'minitest'        
  gem 'mini_specunit'     
  gem 'mini_backtrace'    
end

 group :development, :test do
   gem 'rspec-rails'
   gem 'rb-fsevent', :require => false if RUBY_PLATFORM =~ /darwin/i
   gem 'guard-rspec'
   gem 'guard-livereload'
   gem 'factory_girl_rails'
   gem 'shoulda-matchers'
   gem 'hirb'
   gem 'ruby-prof'
 end

gem 'devise'
gem "gchartrb", :require=> 'google_chart'
gem 'kaminari'
gem 'simple_form'
gem 'resque'
gem 'foreman'
gem 'htmlentities'
gem 'nokogiri'
gem 'feedzirra'
gem 'textstats'