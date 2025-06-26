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

### 2. MCPサーバーの起動

Railsアプリケーションのルートディレクトリで以下を実行：

```bash
bundle exec copy-tuner-mcp
```

### 3. AIアシスタントでの利用

MCPプロトコルに対応したAIアシスタント（Claude Desktop等）で、以下のような操作が可能になります。

*注: AIアシスタントに指示を出す際には、i18nのバックエンドにcopy-tunerを利用していることを伝えてください。*

#### キーの検索
```
user.nameに関連するi18nキーを検索してください
```

#### 翻訳内容の検索
```
「ログイン」という文字を含む翻訳を検索してください
```

#### 新しいキーの作成
```
user.profile.bioというキーで「プロフィール」（日本語）と「Profile」（英語）の翻訳を作成してください
```

### 4. 設定例

#### VSCode Copilot

`.vscode/mcp.json`
```json
{
  "servers": {
    "copy-tuner": {
      "type": "stdio",
      "command": "bundle",
      "args": ["exec", "copy-tuner-mcp"],
      "cwd": "${workspaceFolder}"
    },
  }
}
```

#### Claude Code

`.mcp.json`
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

## ライセンス

このgemは[MIT License](https://opensource.org/licenses/MIT)の下でオープンソースとして利用可能です。
