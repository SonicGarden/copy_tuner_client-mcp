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

    let(:mock_cache) { double("cache") }

    before do
      allow(CopyTunerClient).to receive(:cache).and_return(mock_cache)
      allow(mock_cache).to receive(:[]=)
      allow(mock_cache).to receive(:flush)
    end

    it "creates i18n keys for multiple locales" do
      response = described_class.call(key: key, translations: translations, server_context: server_context)

      expect(mock_cache).to have_received(:[]=).with("ja.new.test.key", "新しいテストキー")
      expect(mock_cache).to have_received(:[]=).with("en.new.test.key", "New Test Key")
      expect(mock_cache).to have_received(:flush)

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.is_error).to be(false)
      expect(response.content.first[:text]).to include("Started creating i18n key #{key}")
      expect(response.content.first[:text]).to include("locales: ja, en")
    end

    it "handles single locale translation" do
      single_translation = [{ locale: "ja", value: "単一ロケール" }]

      response = described_class.call(key: key, translations: single_translation, server_context: server_context)

      expect(mock_cache).to have_received(:[]=).with("ja.new.test.key", "単一ロケール")
      expect(mock_cache).to have_received(:flush)

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.content.first[:text]).to include("locales: ja")
    end
  end
end
