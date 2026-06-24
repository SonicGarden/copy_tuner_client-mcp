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

    it "複数ロケールのローカライズを含む一括 draft blurb を作成する" do
      response = described_class.call(key: key, translations: translations, server_context: server_context)

      expect(api_client).to have_received(:create_sync_bulk_draft_blurbs).with(
        [{ key: key, localizations: { "ja" => "新しいテストキー", "en" => "New Test Key" } }]
      )

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.error?).to be(false)
      expect(response.content.first[:text]).to include(key)
      expect(response.content.first[:text]).to include("ja, en")
    end

    it "単一ロケールの翻訳を処理する" do
      single_translation = [{ locale: "ja", value: "単一ロケール" }]

      response = described_class.call(key: key, translations: single_translation, server_context: server_context)

      expect(api_client).to have_received(:create_sync_bulk_draft_blurbs).with(
        [{ key: key, localizations: { "ja" => "単一ロケール" } }]
      )
      expect(response.error?).to be(false)
    end

    it "API 呼び出しが失敗したときエラーレスポンスを返す" do
      allow(api_client).to receive(:create_sync_bulk_draft_blurbs)
        .and_raise(CopyTunerClient::Mcp::ApiError, "Locale count limit over.")

      response = described_class.call(key: key, translations: translations, server_context: server_context)

      expect(response.error?).to be(true)
      expect(response.content.first[:text]).to include("Locale count limit over.")
    end

    context "wait を指定しない（デフォルト）とき" do
      it "キャッシュをポーリングせず即座に成功を返す" do
        cache = double("cache")
        allow(cache).to receive(:download)
        allow(CopyTunerClient).to receive(:cache).and_return(cache)

        response = described_class.call(key: key, translations: translations, server_context: server_context)

        expect(cache).not_to have_received(:download)
        expect(response.error?).to be(false)
      end
    end

    context "wait が true のとき" do
      let(:cache) { double("cache") }

      before do
        allow(CopyTunerClient).to receive(:cache).and_return(cache)
        allow(cache).to receive(:download)
        # 実時間で待たないよう sleep をスタブ
        allow(described_class).to receive(:sleep)
      end

      it "blurbs にキーが反映されるまで download でキャッシュをポーリングする" do
        # 1回目: 未反映 / 2回目: blurbs に反映
        allow(cache).to receive(:blurbs).and_return({}, { "ja.#{key}" => "新しいテストキー", "en.#{key}" => "New Test Key" })
        allow(cache).to receive(:blank_keys).and_return(Set.new)

        response = described_class.call(key: key, translations: translations, server_context: server_context,
                                        wait: true)

        expect(cache).to have_received(:download).at_least(:once)
        expect(response.error?).to be(false)
        expect(response.content.first[:text]).to include("Confirmed in cache")
      end

      it "書き込んだ値と一致するまで古い値を反映済みと見なさない" do
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

      it "blank_keys への反映を確認済みと見なす" do
        single = [{ locale: "ja", value: "" }]
        allow(cache).to receive(:blurbs).and_return({})
        allow(cache).to receive(:blank_keys).and_return(Set.new, Set.new(["ja.#{key}"]))

        response = described_class.call(key: key, translations: single, server_context: server_context, wait: true)

        expect(response.error?).to be(false)
        expect(response.content.first[:text]).to include("Confirmed in cache")
      end

      it "タイムアウト内に反映されないとき警告付きで成功を返す" do
        allow(cache).to receive(:blurbs).and_return({})
        allow(cache).to receive(:blank_keys).and_return(Set.new)
        # 単調時間をスタブして即タイムアウトさせる（0 秒 → 上限超過）
        allow(described_class).to receive(:monotonic_time).and_return(0.0, 1_000.0)

        response = described_class.call(key: key, translations: translations, server_context: server_context,
                                        wait: true)

        expect(response.error?).to be(false)
        expect(response.content.first[:text]).to include("not confirmed")
      end

      it "API 呼び出しが失敗したときキャッシュをポーリングしない" do
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
