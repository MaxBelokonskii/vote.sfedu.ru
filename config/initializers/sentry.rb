Sentry.init do |config|
  config.dsn = ENV.fetch("SENTRY_URL", nil)
  config.enabled_environments = ["production"]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.send_default_pii = false
end
