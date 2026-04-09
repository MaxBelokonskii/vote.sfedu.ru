module OneCApi
  module SoapConnectable
    extend ActiveSupport::Concern

    included do
      extend Savon::Model

      client wsdl: ENV.fetch("SFEDU_WSDL_PATH", nil),
        soap_header: {username: ENV.fetch("SFEDU_WSDL_USERNAME", nil), password: ENV.fetch("SFEDU_WSDL_PASSWORD", nil)},
        basic_auth: [ENV.fetch("SFEDU_WSDL_USERNAME", nil), ENV.fetch("SFEDU_WSDL_PASSWORD", nil)],
        open_timeout: Integer(ENV.fetch("SOAP_OPEN_TIMEOUT", 10)),
        read_timeout: Integer(ENV.fetch("SOAP_READ_TIMEOUT", 30))

      global :env_namespace, :soap
      global :namespace_identifier, :perf
      global :convert_request_keys_to, :camelcase
    end
  end
end
