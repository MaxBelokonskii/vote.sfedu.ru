Rails.application.configure do
  config.middleware.use Rack::CanonicalHost, ENV.fetch("APPLICATION_HOST")
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.assets.js_compressor = :terser
  config.assets.compile = false
  config.action_controller.asset_host = ENV.fetch("ASSET_HOST", ENV.fetch("APPLICATION_HOST"))
  config.log_level = :info
  config.log_tags = [:request_id]
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :graph
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)
  config.active_record.dump_schema_after_migration = false
  config.action_mailer.default_url_options = {host: ENV.fetch("APPLICATION_HOST")}
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = {database: {writing: :primary}}

  # SSL-терминация происходит на внешнем reverse proxy заказчика.
  # Proxy должен передавать заголовок X-Forwarded-Proto=https — тогда
  # ActionDispatch::SSL не инициирует повторный редирект, но добавит
  # HSTS и пометит cookies как Secure. Если proxy не добавляет заголовок,
  # выключите force_ssl через RAILS_FORCE_SSL=false и настройте редирект
  # с HSTS на стороне proxy.
  config.force_ssl = ENV.fetch("RAILS_FORCE_SSL", "true") == "true"

  # Explicitly set the Secure and HttpOnly flags on the session cookie so that
  # session tokens are never sent over plain HTTP, regardless of force_ssl.
  # This is necessary because setting force_ssl=false disables ActionDispatch::SSL
  # entirely, which would otherwise set these flags automatically.
  config.session_store :cookie_store,
    key: "_vote_session",
    secure: true,
    httponly: true,
    same_site: :lax
end
