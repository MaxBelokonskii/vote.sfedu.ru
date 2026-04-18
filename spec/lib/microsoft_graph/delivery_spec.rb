require "rails_helper"
require "webmock/rspec"
require Rails.root.join("lib/microsoft_graph/delivery")

RSpec.describe MicrosoftGraph::Delivery do
  let(:settings) do
    {
      tenant_id: "tenant-abc",
      client_id: "app-id",
      client_secret: "secret",
      sender: "noreply@example.com"
    }
  end

  let(:mail) do
    Mail.new do
      from "noreply@example.com"
      to "user@example.com"
      subject "Привет"
      body "Тело письма"
    end
  end

  let(:token_url) { "https://login.microsoftonline.com/tenant-abc/oauth2/v2.0/token" }
  let(:send_url)  { "https://graph.microsoft.com/v1.0/users/noreply@example.com/sendMail" }

  subject(:delivery) { described_class.new(settings) }

  describe "#deliver!" do
    it "получает токен и отправляет письмо" do
      token_stub = stub_request(:post, token_url)
        .with(body: hash_including("grant_type" => "client_credentials"))
        .to_return(status: 200, body: {access_token: "TOKEN"}.to_json, headers: {"Content-Type" => "application/json"})

      send_stub = stub_request(:post, send_url)
        .with(headers: {"Authorization" => "Bearer TOKEN", "Content-Type" => "application/json"})
        .to_return(status: 202, body: "")

      delivery.deliver!(mail)

      expect(token_stub).to have_been_requested
      expect(send_stub).to have_been_requested
    end

    it "передаёт корректный payload" do
      stub_request(:post, token_url).to_return(status: 200, body: '{"access_token":"T"}')
      send_stub = stub_request(:post, send_url).with { |req|
        payload = JSON.parse(req.body)
        expect(payload.dig("message", "subject")).to eq("Привет")
        expect(payload.dig("message", "toRecipients", 0, "emailAddress", "address")).to eq("user@example.com")
        expect(payload["saveToSentItems"]).to be(false)
        true
      }.to_return(status: 202)

      delivery.deliver!(mail)

      expect(send_stub).to have_been_requested
    end

    it "кидает DeliveryError если токен не выдан" do
      stub_request(:post, token_url).to_return(status: 401, body: '{"error":"unauthorized"}')

      expect { delivery.deliver!(mail) }.to raise_error(MicrosoftGraph::DeliveryError, /401/)
    end

    it "кидает DeliveryError если ответ 200 без access_token" do
      stub_request(:post, token_url)
        .to_return(status: 200, body: '{"error":"invalid_client"}', headers: {"Content-Type" => "application/json"})

      expect { delivery.deliver!(mail) }.to raise_error(MicrosoftGraph::DeliveryError, /Некорректный ответ OAuth2/)
    end

    it "обрезает тело ответа в сообщении об ошибке" do
      long_body = "x" * 1000
      stub_request(:post, token_url).to_return(status: 500, body: long_body)

      expect { delivery.deliver!(mail) }.to raise_error(MicrosoftGraph::DeliveryError) { |e|
        expect(e.message.length).to be < 500
      }
    end

    it "кидает DeliveryError если sendMail вернул ошибку" do
      stub_request(:post, token_url).to_return(status: 200, body: '{"access_token":"T"}')
      stub_request(:post, send_url).to_return(status: 500, body: "oops")

      expect { delivery.deliver!(mail) }.to raise_error(MicrosoftGraph::DeliveryError, /500/)
    end

    it "валидирует обязательные настройки" do
      expect { described_class.new(settings.merge(tenant_id: nil)) }
        .to raise_error(MicrosoftGraph::DeliveryError, /tenant_id/)
    end
  end
end
