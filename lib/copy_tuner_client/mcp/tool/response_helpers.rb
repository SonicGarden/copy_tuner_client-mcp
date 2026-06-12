# frozen_string_literal: true

require "mcp"
require "copy_tuner_client/mcp"

module CopyTunerClient
  module Mcp
    module Tool
      # i18n 書き込みツール共通のヘルパー: 翻訳データの変換、API エラーハンドリング、
      # テキスト形式の MCP::Tool::Response 構築を提供する。
      module ResponseHelpers
        # ツールの `translations` 配列を CopyTuner のローカライズハッシュに変換し、
        # ブロック（API 呼び出しを実施）に yield して、結果または ApiError を
        # MCP::Tool::Response にラップして返す。
        #
        # @param verb [String] past-tense action for the success message (e.g. "Created")
        # @param failed_verb [String] action for the error message (e.g. "create")
        def run_i18n_tool(key:, translations:, verb:)
          localizations = translations.to_h { |t| [t[:locale], t[:value]] }

          yield localizations

          success_response("#{verb} i18n key #{key}. (locales: #{localizations.keys.join(", ")})")
        rescue CopyTunerClient::Mcp::ApiError => e
          error_response("Failed to #{verb.downcase} i18n key #{key}: #{e.message}")
        end

        def success_response(text)
          MCP::Tool::Response.new([{ type: "text", text: text }])
        end

        def error_response(text)
          MCP::Tool::Response.new([{ type: "text", text: text }], error: true)
        end
      end
    end
  end
end
