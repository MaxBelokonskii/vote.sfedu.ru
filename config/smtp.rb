SMTP_SETTINGS = {
  address: ENV["SMTP_ADDRESS"],
  authentication: :plain,
  domain: ENV["SMTP_DOMAIN"],
  enable_starttls_auto: true,
  password: ENV["SMTP_PASSWORD"],
  port: ENV.fetch("SMTP_PORT", "587"),
  user_name: ENV["SMTP_USERNAME"]
}.freeze

if ENV["EMAIL_RECIPIENTS"].present?
  Mail.register_interceptor RecipientInterceptor.new(ENV["EMAIL_RECIPIENTS"])
end
