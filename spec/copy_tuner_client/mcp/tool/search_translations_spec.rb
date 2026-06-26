# frozen_string_literal: true

require "copy_tuner_client/mcp/tool/search_translations"

RSpec.describe CopyTunerClient::Mcp::Tool::SearchTranslations do
  describe ".call" do
    let(:server_context) { double("server_context") }
    let(:query) { "テスト" }
    let(:locale) { "ja" }

    before do
      # Mock CopyTunerClient.cache.blurbs
      allow(CopyTunerClient).to receive(:cache).and_return(
        double("cache", blurbs: {
          "ja.test_key" => "テストキー",
          "ja.another_key" => "別のテスト内容",
          "en.test_key" => "Test Key"
        })
      )
    end

    it "クエリテキストを含む一致する翻訳を返す" do
      response = described_class.call(query: query, server_context: server_context, locale: locale)

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.error?).to be(false)
      expect(response.content.first[:type]).to eq("text")

      result = JSON.parse(response.content.first[:text])
      expect(result).to include("test_key" => "テストキー")
      expect(result).to include("another_key" => "別のテスト内容")
      expect(result).not_to include("test_key" => "Test Key") # English translation should not be included
    end

    it "翻訳が一致しないとき空の結果を返す" do
      response = described_class.call(query: "存在しない", server_context: server_context, locale: locale)

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.error?).to be(true)

      result = JSON.parse(response.content.first[:text])
      expect(result).to be_empty
    end

    it "ロケールを指定しないとき 'ja' をデフォルトとして使う" do
      response = described_class.call(query: query, server_context: server_context)

      expect(response).to be_a(MCP::Tool::Response)
      result = JSON.parse(response.content.first[:text])
      expect(result).to include("test_key" => "テストキー")
    end
  end
end
