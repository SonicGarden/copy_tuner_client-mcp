# frozen_string_literal: true

require "mcp"
require "json"

module CopyTunerClient
  module Mcp
    module Tool
      # TODO: 最終的には同期登録可能にしたいが、まずは既存APIに変更を加えずに登録可能としている
      class CreateI18nKey < MCP::Tool
        tool_name "create_i18n_key"
        description "Create a new Rails i18n translation key in the copy_tuner project. This tool registers new keys to the translation database asynchronously. The registration process starts immediately, but the actual creation and availability may take some time to complete due to the asynchronous nature of the system."
        input_schema(
          properties: {
            key: { type: "string", description: "The i18n key to register" },
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
              description: "Additional translations for the key in different locales"
            }
          },
          required: ["key"]
        )

        class << self
          def call(key:, translations:, server_context:) # rubocop:disable Lint/UnusedMethodArgument
            # NOTE: 同一キーの複数言語はcopytunerの仕様上同時に登録する必要がある
            locales =
              translations.map do |translation|
                full_key = [translation[:locale], key].join(".")
                CopyTunerClient.cache[full_key] = translation[:value]
                translation[:locale]
              end
            CopyTunerClient.cache.flush

            MCP::Tool::Response.new([{
              type: "text",
              text: "Started creating i18n key #{key}. (locales: #{locales.join(", ")})"
            }])
          end
        end
      end
    end
  end
end
