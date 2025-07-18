# CopyTunerClient::Mcp

Rails i18nの翻訳管理サービス「CopyTuner」のMCP（Model Context Protocol）サーバー実装です。AIアシスタントがRailsアプリケーションの多言語化対応を効率的に支援するためのツールセットを提供します。

## 概要

このgemは、CopyTunerプロジェクトの翻訳データにアクセスし、Rails i18nキーの検索、翻訳の管理、新しいキーの作成などをMCPプロトコル経由で実行できるサーバーを提供します。

## 機能

### 利用可能なツール

- **search_key**: Rails i18nキーの検索（`t()`や`I18n.t()`で使用されるキーの検索に最適化）
- **search_translations**: 翻訳内容による検索（特定のテキストを含む翻訳の検索）
- **create_i18n_key**: 新しいi18nキーの作成（複数言語対応、非同期処理）
- **get_locales**: プロジェクトで使用中のロケール一覧の取得
- **get_edit_url**: 登録済みキーの編集画面URLの生成

### リソーステンプレート

- `copytuner://projects/{project_id}/translations/{locale}/{key}`: 個別の翻訳リソースへのアクセス

## インストール

Gemfileに以下を追加：

```ruby
group :development do
  gem 'copy_tuner_client-mcp', github: 'SonicGarden/copy_tuner_client-mcp', require: false
end
```

そして実行：

```bash
bundle install
```

## 使用方法

### 1. CopyTunerClientの設定

まず、Railsアプリケーションでcopy_tuner_clientが適切に設定されている必要があります：

```ruby
# config/initializers/copy_tuner_client.rb
CopyTunerClient.configure do |config|
  config.api_key = "your-api-key"
  config.project_id = "your-project-id"
  config.locales = ["ja", "en"]
end
```

### 2. AIアシスタントでの設定と利用

MCPプロトコルに対応したAIアシスタント（Claude Code、VSCode Copilot等）で、以下の設定ファイルを配置するとMCPサーバーが自動的に起動され、翻訳管理機能が利用可能になります。

#### Claude Code

プロジェクトのルートディレクトリに `.mcp.json` ファイルを作成：

```json
{
  "mcpServers": {
    "copy-tuner": {
      "command": "bundle",
      "args": ["exec", "copy-tuner-mcp"]
    }
  }
}
```

#### VSCode Copilot

`.vscode/mcp.json` ファイルを作成：

```json
{
  "servers": {
    "copy-tuner": {
      "type": "stdio",
      "command": "bundle",
      "args": ["exec", "copy-tuner-mcp"],
      "cwd": "${workspaceFolder}"
    }
  }
}
```

#### CLAUDE.md設定例

プロジェクトのルートディレクトリに `CLAUDE.yml` ファイルを作成することで、AIアシスタントがプロジェクトの国際化の仕組みを理解できるようになります：

```markdown
# CLAUDE.md

## 国際化（i18n）について
- i18nのバックエンドには**copy_tuner**というサーバでi18nデータを管理する仕組みを利用
- i18nのキーや内容を参照する場合は、copy_tunerから取得する必要がある
- `config/locales` 配下のファイルは利用していません
- copy_tunerサーバと連携してローカライズデータを管理
```

#### 使用例

設定完了後、AIアシスタントで以下のような操作が可能になります：

##### キーの検索
```
user.nameに関連するi18nキーを検索してください
```

##### 翻訳内容の検索
```
「ログイン」という文字を含む翻訳を検索してください
```

##### 新しいキーの作成
```
user.profile.bioというキーで「プロフィール」（日本語）と「Profile」（英語）の翻訳を作成してください
```

### 3. 手動起動（動作確認・デバッグ用）

通常はAIアシスタントの設定ファイルを通じて自動的に起動されますが、動作確認やデバッグが必要な場合は、Railsアプリケーションのルートディレクトリで以下を実行して手動起動できます：

```bash
bundle exec copy-tuner-mcp
```

## ライセンス

このgemは[MIT License](https://opensource.org/licenses/MIT)の下でオープンソースとして利用可能です。
