# CLAUDE.md

CopyTuner（Rails i18n 翻訳管理サービス）の MCP サーバー実装 gem。AIアシスタントが
Rails アプリの i18n キー検索・翻訳の作成/更新を MCP 経由で行うためのツール群を提供する。

## Commands
- `bundle exec rake`     — デフォルト: spec を実行（CI と同じ）
- `bundle exec rspec`    — テストのみ
- `bundle exec rubocop`  — Lint

## Development
- **RED/TDD で進める**: 実装前に必ず失敗するテストを書き、テストが RED になることを
  確認してから実装する。新機能・バグ修正ともに「テスト追加 → RED 確認 → 実装 →
  GREEN」のサイクルを守る。テストを書かずに実装を先行させない。
- **コメントは WHY のみ日本語で書く**: 識別子やコードから読み取れる WHAT は書かない。
- **テストの `describe` / `context` / `it` の説明文は日本語で書く**: 識別子
  （クラス名・メソッド名など）はそのまま。

## Architecture
- `exe/copy-tuner-mcp` — stdio MCP サーバーのエントリポイント。ツール登録とリソース
  テンプレートを定義する。
- `lib/copy_tuner_client/mcp/tool/*.rb` — 各 MCP ツール（`MCP::Tool` のサブクラス）。
  `tool.rb` が glob で自動 require する。
- `lib/copy_tuner_client/mcp/api_client.rb` — CopyTuner API v3 への薄い Net::HTTP クライアント。

### 読み取り系と書き込み系でデータソースが異なる
- 読み取り（search_key / search_translations / get_locales）: プロセス内の
  `CopyTunerClient.cache` を参照。
- 書き込み（create_i18n_key / update_i18n_key）: `ApiClient` 経由で API v3 に HTTP。
  draft として非同期登録され、読み取り側には即時反映されない。

## Gotchas
- `exe/copy-tuner-mcp` は `config/environment` を require するため、copy_tuner_client が
  設定済みのホスト Rails アプリ内でしか起動できない（この repo 単体では動かない）。
- 新しいツールを追加したら、ファイルを作るだけでなく `exe/copy-tuner-mcp` の `tools:`
  配列にも登録する必要がある（未登録だと公開されない）。
- 書き込みツールは `ResponseHelpers` を include し、`MCP::Tool::Response` を返す。
- spec では `CopyTunerClient.cache` / `.configuration` を double でモックする。
- Ruby: gemspec/rubocop は 3.1 を対象、CI は 3.4.2 で実行。
