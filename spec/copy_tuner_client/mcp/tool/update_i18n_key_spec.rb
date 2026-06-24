# frozen_string_literal: true

require "copy_tuner_client/mcp/tool/update_i18n_key"

RSpec.describe CopyTunerClient::Mcp::Tool::UpdateI18nKey do
  describe ".call" do
    let(:server_context) { double("server_context") }
    let(:key) { "existing.test.key" }
    let(:translations) do
      [
        { locale: "ja", value: "更新後の値" },
        { locale: "en", value: "Updated value" }
      ]
    end

    let(:api_client) { instance_double(CopyTunerClient::Mcp::ApiClient) }

    before do
      allow(CopyTunerClient::Mcp::ApiClient).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:update_draft_blurb)
        .and_return({ "message" => "Draft blurb localizations updated successfully" })
    end

    it "updates the draft blurb localizations for the given key" do
      response = described_class.call(key: key, translations: translations, server_context: server_context)

      expect(api_client).to have_received(:update_draft_blurb).with(
        key, { "ja" => "更新後の値", "en" => "Updated value" }
      )

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.error?).to be(false)
      expect(response.content.first[:text]).to include(key)
      expect(response.content.first[:text]).to include("ja, en")
    end

    it "returns an error response when the key is already published" do
      message = "Some translations cannot be updated. " \
                "Translation for locale 'en' has been published and cannot be updated via API."
      allow(api_client).to receive(:update_draft_blurb)
        .and_raise(CopyTunerClient::Mcp::ApiError, message)

      response = described_class.call(key: key, translations: translations, server_context: server_context)

      expect(response.error?).to be(true)
      expect(response.content.first[:text]).to include("has been published and cannot be updated via API")
    end

    context "when wait is true" do
      let(:cache) { double("cache") }

      before do
        allow(CopyTunerClient).to receive(:cache).and_return(cache)
        allow(cache).to receive(:download)
        allow(described_class).to receive(:sleep)
      end

      it "polls the cache until the key is reflected" do
        allow(cache).to receive(:blurbs).and_return({}, { "ja.#{key}" => "更新後の値", "en.#{key}" => "Updated value" })
        allow(cache).to receive(:blank_keys).and_return(Set.new)

        response = described_class.call(key: key, translations: translations, server_context: server_context,
                                        wait: true)

        expect(cache).to have_received(:download).at_least(:once)
        expect(response.error?).to be(false)
        expect(response.content.first[:text]).to include("Confirmed in cache")
      end
    end
  end
end
