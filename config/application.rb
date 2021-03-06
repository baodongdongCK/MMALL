# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

ENV['ALIPAY_MD5_SECRET'] = '5o1iuxgxze13lq2hq71tq9j38i7xi4p3'
ENV['ALIPAY_URL'] = 'https://openapi.alipaydev.com/gateway.do'
ENV['ALIPAY_RETURN_URL'] = 'http://localhost:3000/payments/pay_return'
ENV['ALIPAY_NOTIFY_URL'] = 'http://localhost:3000/payments/pay_notify'

module MasterRailsByActions
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # config.enable_dependency_loading = true
    # config.autoload_paths += Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')
    config.active_job.queue_adapter = :sidekiq
    config.generators do |generator|
      generator.assets false
      generator.helper false
      generator.test_framework = :rspec
      generator.skip_routes true
      generator.fixture_replacement :factory_girl
      generator.factory_girl dir: 'spec/factories'
    end

    # email config
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_deliveries = true
    # config.action_mailer.default_url_options = { host: '173.194.193.108' }
    config.action_mailer.smtp_settings = {
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'gmail.com',
      user_name:            'bao1214063293@gmail.com',
      password:             'ccc6986221',
      authentication:       :plain,
      enable_starttls_auto: true
      # ssl:  true
    }
  end
end
