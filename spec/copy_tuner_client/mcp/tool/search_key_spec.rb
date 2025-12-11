# frozen_string_literal: true

require "copy_tuner_client/mcp/tool/search_key"

RSpec.describe CopyTunerClient::Mcp::Tool::SearchKey do
  describe ".call" do
    let(:server_context) { double("server_context") }
    let(:query) { "test_key" }
    let(:locale) { "ja" }

    before do
      # Mock CopyTunerClient.cache.blurbs
      allow(CopyTunerClient).to receive(:cache).and_return(
        double("cache", blurbs: {
                 "ja.test_key" => "テストキー",
                 "ja.another_test_key" => "別のテストキー",
                 "en.test_key" => "Test Key"
               })
      )
    end

    it "returns matching keys for the specified locale" do
      response = described_class.call(query: query, server_context: server_context, locale: locale)

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.error?).to be(false)
      expect(response.content.first[:type]).to eq("text")

      result = JSON.parse(response.content.first[:text])
      expect(result).to include("test_key" => "テストキー")
      expect(result).to include("another_test_key" => "別のテストキー")
      expect(result).not_to include("en.test_key")
    end

    it "returns empty result when no keys match" do
      response = described_class.call(query: "nonexistent", server_context: server_context, locale: locale)

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.error?).to be(true)

      result = JSON.parse(response.content.first[:text])
      expect(result).to be_empty
    end

    it "uses 'ja' as default locale when not specified" do
      response = described_class.call(query: query, server_context: server_context)

      expect(response).to be_a(MCP::Tool::Response)
      result = JSON.parse(response.content.first[:text])
      expect(result).to include("test_key" => "テストキー")
    end
  end
end
