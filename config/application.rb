require File.expand_path('../boot', __FILE__)

require 'rails/all'
require_relative '../lib/configuration.rb' # Loads Houston's configuration
require_relative '../lib/houston_server.rb' # Loads Houston's configuration

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Houston
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'
    
    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql
    
    # SMTP settings
    config.action_mailer.smtp_settings = Houston.config.smtp
    config.action_mailer.default_options = {from: Houston.config.mailer_from}
    
    # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
    config.assets.precompile += %w( print.css )
    
    # While implementing strong parameters!
    config.action_controller.permit_all_parameters = true
    
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    # Automatically compress responses that accept gzip encoding
    config.middleware.use Rack::Deflater
  end
end

Houston.observer.fire "boot"
