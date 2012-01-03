APP_CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")
Nc3::Application.config.secret_token = APP_CONFIG['secret_token']