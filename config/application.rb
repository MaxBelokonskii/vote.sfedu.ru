require_relative "boot"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"

require "dry/monads"
require "dry/transaction/operation"

Bundler.require(*Rails.groups)
module VoteSfeduRu
  class Application < Rails::Application
    config.assets.quiet = true
    config.generators do |generate|
      generate.helper false
      generate.javascript_engine false
      generate.request_specs false
      generate.routing_specs false
      generate.stylesheets false
      generate.test_framework :rspec
      generate.factory_bot filename_proc: ->(table_name) { "#{table_name.singularize}_factory" }
      generate.view_specs false
    end

    config.autoload_paths << "#{Rails.root}/lib"
    config.eager_load_paths << "#{Rails.root}/lib"

    config.time_zone = "Moscow"
    config.active_record.default_timezone = :utc

    config.i18n.default_locale = :ru
    config.i18n.available_locales = [:ru, :en]

    config.action_controller.action_on_unpermitted_parameters = :raise
    config.load_defaults 7.2
    config.generators.system_tests = nil

    config.exceptions_app = routes

    # Trust the Docker bridge network (внешний reverse-proxy заказчика
    # шлёт запросы на опубликованный хост-порт, а внутри контейнера
    # REMOTE_ADDR — это IP шлюза Docker-сети, обычно из 172.16.0.0/12).
    # ActionDispatch::RemoteIp достанет реальный IP клиента из X-Forwarded-For.
    # Если ваш proxy ходит из другого диапазона, переопределите через
    # TRUSTED_PROXY_CIDR (например, "10.1.2.0/24").
    trusted_cidr = ENV.fetch("TRUSTED_PROXY_CIDR", "172.16.0.0/12")
    config.action_dispatch.trusted_proxies =
      ActionDispatch::RemoteIp::TRUSTED_PROXIES + [IPAddr.new(trusted_cidr)]
  end
end
