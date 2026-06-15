# frozen_string_literal: true

require "copy_tuner_client/mcp/tool/create_i18n_key"

RSpec.describe CopyTunerClient::Mcp::Tool::CreateI18nKey do
  describe ".call" do
    let(:server_context) { double("server_context") }
    let(:key) { "new.test.key" }
    let(:translations) do
      [
        { locale: "ja", value: "新しいテストキー" },
        { locale: "en", value: "New Test Key" }
      ]
    end

    let(:api_client) { instance_double(CopyTunerClient::Mcp::ApiClient) }

    before do
      allow(CopyTunerClient::Mcp::ApiClient).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:create_sync_bulk_draft_blurbs)
        .and_return({ "message" => "Draft blurbs created successfully" })
    end

    it "creates a bulk draft blurb with localizations for multiple locales" do
      response = described_class.call(key: key, translations: translations, server_context: server_context)

      expect(api_client).to have_received(:create_sync_bulk_draft_blurbs).with(
        [{ key: key, localizations: { "ja" => "新しいテストキー", "en" => "New Test Key" } }]
      )

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.error?).to be(false)
      expect(response.content.first[:text]).to include(key)
      expect(response.content.first[:text]).to include("ja, en")
    end

    it "handles single locale translation" do
      single_translation = [{ locale: "ja", value: "単一ロケール" }]

      response = described_class.call(key: key, translations: single_translation, server_context: server_context)

      expect(api_client).to have_received(:create_sync_bulk_draft_blurbs).with(
        [{ key: key, localizations: { "ja" => "単一ロケール" } }]
      )
      expect(response.error?).to be(false)
    end

    it "returns an error response when the API call fails" do
      allow(api_client).to receive(:create_sync_bulk_draft_blurbs)
        .and_raise(CopyTunerClient::Mcp::ApiError, "Locale count limit over.")

      response = described_class.call(key: key, translations: translations, server_context: server_context)

      expect(response.error?).to be(true)
      expect(response.content.first[:text]).to include("Locale count limit over.")
    end
  end
end
