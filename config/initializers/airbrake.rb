Airbrake.configure do |config|
  config.api_key = '1206d403d2f377148df0b76af8f2ae65'
  config.host    = 'nc-errbit.herokuapp.com'
  config.port    = 80
  config.secure  = config.port == 443
end