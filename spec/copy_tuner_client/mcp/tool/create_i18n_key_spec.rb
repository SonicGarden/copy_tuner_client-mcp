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

    context "when wait is not specified (default)" do
      it "does not poll the cache and returns success immediately" do
        cache = double("cache")
        allow(CopyTunerClient).to receive(:cache).and_return(cache)

        response = described_class.call(key: key, translations: translations, server_context: server_context)

        expect(cache).not_to have_received(:download) if cache.respond_to?(:download)
        expect(response.error?).to be(false)
      end
    end

    context "when wait is true" do
      let(:cache) { double("cache") }

      before do
        allow(CopyTunerClient).to receive(:cache).and_return(cache)
        allow(cache).to receive(:download)
        # 実時間で待たないよう sleep をスタブ
        allow(described_class).to receive(:sleep)
      end

      it "polls the cache via download until the key is reflected in blurbs" do
        # 1回目: 未反映 / 2回目: blurbs に反映
        allow(cache).to receive(:blurbs).and_return({}, { "ja.#{key}" => "新しいテストキー", "en.#{key}" => "New Test Key" })
        allow(cache).to receive(:blank_keys).and_return(Set.new)

        response = described_class.call(key: key, translations: translations, server_context: server_context,
                                        wait: true)

        expect(cache).to have_received(:download).at_least(:once)
        expect(response.error?).to be(false)
        expect(response.content.first[:text]).to include("Confirmed in cache")
      end

      it "does not treat a stale value as reflected until it matches the written value" do
        # 1回目: 古い値（未反映） / 2回目: 書き込んだ値に一致（反映）
        allow(cache).to receive(:blurbs).and_return(
          { "ja.#{key}" => "古い値", "en.#{key}" => "old" },
          { "ja.#{key}" => "新しいテストキー", "en.#{key}" => "New Test Key" }
        )
        allow(cache).to receive(:blank_keys).and_return(Set.new)

        response = described_class.call(key: key, translations: translations, server_context: server_context,
                                        wait: true)

        expect(cache).to have_received(:download).twice
        expect(response.error?).to be(false)
        expect(response.content.first[:text]).to include("Confirmed in cache")
      end

      it "treats blank_keys reflection as confirmed" do
        single = [{ locale: "ja", value: "" }]
        allow(cache).to receive(:blurbs).and_return({})
        allow(cache).to receive(:blank_keys).and_return(Set.new, Set.new(["ja.#{key}"]))

        response = described_class.call(key: key, translations: single, server_context: server_context, wait: true)

        expect(response.error?).to be(false)
        expect(response.content.first[:text]).to include("Confirmed in cache")
      end

      it "returns success with a warning when the key is not reflected within the timeout" do
        allow(cache).to receive(:blurbs).and_return({})
        allow(cache).to receive(:blank_keys).and_return(Set.new)
        # 単調時間をスタブして即タイムアウトさせる（0 秒 → 上限超過）
        allow(described_class).to receive(:monotonic_time).and_return(0.0, 1_000.0)

        response = described_class.call(key: key, translations: translations, server_context: server_context,
                                        wait: true)

        expect(response.error?).to be(false)
        expect(response.content.first[:text]).to include("not confirmed")
      end

      it "does not poll the cache when the API call fails" do
        allow(api_client).to receive(:create_sync_bulk_draft_blurbs)
          .and_raise(CopyTunerClient::Mcp::ApiError, "boom")

        response = described_class.call(key: key, translations: translations, server_context: server_context,
                                        wait: true)

        expect(cache).not_to have_received(:download)
        expect(response.error?).to be(true)
      end
    end
  end
end
