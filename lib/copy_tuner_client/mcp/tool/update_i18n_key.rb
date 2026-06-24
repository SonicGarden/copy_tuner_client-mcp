# frozen_string_literal: true

require "mcp"
require "json"
require "copy_tuner_client/mcp/api_client"
require "copy_tuner_client/mcp/tool/response_helpers"

module CopyTunerClient
  module Mcp
    module Tool
      # CopyTuner API v3 を通じて既存の i18n キーのドラフトローカライズデータを更新する。
      class UpdateI18nKey < MCP::Tool
        tool_name "update_i18n_key"
        description "Update the draft translations of an existing Rails i18n key in the copy_tuner project. " \
                    "Only translations that are not yet published (or are published but empty) can be updated; " \
                    "attempting to update an already-published translation returns an error. " \
                    "By default, waits until the update is reflected in the local cache (up to 2 minutes). " \
                    "Set wait=false to return immediately without waiting."
        input_schema(
          properties: {
            key: { type: "string", description: "The existing i18n key to update" },
            translations: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  locale: { type: "string", description: "The locale for the translation" },
                  value: { type: "string", description: "The translation value" }
                },
                required: %w[locale value]
              },
              description: "Translations to update for the key in different locales"
            },
            wait: {
              type: "boolean",
              default: true,
              description: "When false, return immediately without waiting for cache reflection. " \
                           "By default (true), wait until the updated key is reflected in the local cache " \
                           "(downloaded from S3) before returning, up to 2 minutes."
            }
          },
          required: %w[key translations]
        )

        class << self
          include ResponseHelpers

          def call(key:, translations:, server_context:, wait: true) # rubocop:disable Lint/UnusedMethodArgument
            run_i18n_tool(key: key, translations: translations, verb: "Updated", wait: wait) do |loc|
              ApiClient.new.update_draft_blurb(key, loc)
            end
          end
        end
      end
    end
  end
end
