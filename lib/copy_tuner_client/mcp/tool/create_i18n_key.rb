# frozen_string_literal: true

require "mcp"
require "json"
require "copy_tuner_client/mcp/api_client"
require "copy_tuner_client/mcp/tool/response_helpers"

module CopyTunerClient
  module Mcp
    module Tool
      # Registers a new draft i18n key with its localizations via the CopyTuner API v3.
      class CreateI18nKey < MCP::Tool
        tool_name "create_i18n_key"
        description "Create a new Rails i18n translation key in the copy_tuner project. " \
                    "This registers a new draft key with translations for one or more locales " \
                    "via the CopyTuner API. The draft is created immediately; publishing happens " \
                    "separately on the CopyTuner side."
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
              description: "Translations for the key in different locales"
            }
          },
          required: ["key"]
        )

        class << self
          include ResponseHelpers

          def call(key:, translations:, server_context:) # rubocop:disable Lint/UnusedMethodArgument
            # NOTE: 同一キーの複数言語はcopytunerの仕様上同時に登録する必要がある
            run_i18n_tool(key: key, translations: translations, verb: "Created", failed_verb: "create") do |loc|
              ApiClient.new.create_bulk_draft_blurbs([{ key: key, localizations: loc }])
            end
          end
        end
      end
    end
  end
end
