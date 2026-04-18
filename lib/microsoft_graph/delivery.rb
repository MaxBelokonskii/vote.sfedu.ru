require "net/http"
require "uri"
require "json"

module MicrosoftGraph
  class DeliveryError < StandardError; end

  # ActionMailer delivery method: отправка писем через Microsoft Graph API
  # с client_credentials OAuth2 (application permission Mail.Send).
  #
  # Регистрация:
  #   ActionMailer::Base.add_delivery_method :graph, MicrosoftGraph::Delivery
  #
  # Активация:
  #   config.action_mailer.delivery_method = :graph
  #
  # Настройки читаются из ENV:
  #   GRAPH_TENANT_ID, GRAPH_CLIENT_ID, GRAPH_CLIENT_SECRET, GRAPH_SENDER_EMAIL
  #
  # Настройки можно переопределить явно (например, в тестах):
  #   MicrosoftGraph::Delivery.new(tenant_id:, client_id:, client_secret:, sender:)
  class Delivery
    TOKEN_URL = "https://login.microsoftonline.com/%<tenant>s/oauth2/v2.0/token".freeze
    SEND_URL = "https://graph.microsoft.com/v1.0/users/%<sender>s/sendMail".freeze
    SCOPE = "https://graph.microsoft.com/.default".freeze
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30
    ERROR_BODY_LIMIT = 300

    def initialize(settings = {})
      @tenant_id = fetch_setting(settings, :tenant_id, "GRAPH_TENANT_ID")
      @client_id = fetch_setting(settings, :client_id, "GRAPH_CLIENT_ID")
      @client_secret = fetch_setting(settings, :client_secret, "GRAPH_CLIENT_SECRET")
      @sender = fetch_setting(settings, :sender, "GRAPH_SENDER_EMAIL")
    end

    def deliver!(mail)
      token = fetch_access_token
      send_mail(mail, token)
    end

    private

    def fetch_setting(settings, key, env_var)
      value = settings[key] || settings[key.to_s] || ENV[env_var]
      raise DeliveryError, "Microsoft Graph delivery: отсутствует настройка #{key} (ENV #{env_var})" if value.to_s.strip.empty?
      value
    end

    def fetch_access_token
      uri = URI(format(TOKEN_URL, tenant: @tenant_id))
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = URI.encode_www_form(
        "client_id" => @client_id,
        "client_secret" => @client_secret,
        "scope" => SCOPE,
        "grant_type" => "client_credentials"
      )
      response = perform(uri, request)
      unless response.is_a?(Net::HTTPSuccess)
        raise DeliveryError, "Не удалось получить OAuth2-токен (HTTP #{response.code}): #{truncate(response.body)}"
      end
      JSON.parse(response.body).fetch("access_token")
    rescue JSON::ParserError, KeyError => e
      raise DeliveryError, "Некорректный ответ OAuth2: #{e.message}"
    end

    def send_mail(mail, token)
      uri = URI(format(SEND_URL, sender: @sender))
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request.body = build_payload(mail).to_json

      response = perform(uri, request)
      return if response.is_a?(Net::HTTPSuccess)
      raise DeliveryError, "Microsoft Graph sendMail вернул HTTP #{response.code}: #{truncate(response.body)}"
    end

    def perform(uri, request)
      Net::HTTP.start(uri.hostname, uri.port,
        use_ssl: true,
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT) { |http| http.request(request) }
    end

    def truncate(body)
      body.to_s[0, ERROR_BODY_LIMIT]
    end

    def build_payload(mail)
      html_body = mail.html_part&.decoded
      text_body = mail.text_part&.decoded
      body_content = html_body || text_body || mail.body.to_s
      content_type = html_body ? "HTML" : "Text"

      {
        message: {
          subject: mail.subject.to_s,
          body: {contentType: content_type, content: body_content},
          toRecipients: recipients(mail.to),
          ccRecipients: recipients(mail.cc),
          bccRecipients: recipients(mail.bcc)
        },
        saveToSentItems: false
      }
    end

    def recipients(addresses)
      Array(addresses).map { |addr| {emailAddress: {address: addr}} }
    end
  end
end
