# frozen_string_literal: true

require "mcp"
require "json"

module CopyTunerClient
  module Mcp
    module Tool
      class SearchTranslations < MCP::Tool
        tool_name "search_translations"
        description "Search and retrieve Rails i18n translations by content. Optimized for finding translations containing specific text, checking translation values across languages, and discovering keys by their translated content. Quickly finds accurate translations and keys from copy_tuner project translation database."
        input_schema(
          properties: {
            query: { type: "string" },
            locale: { type: "string", default: "ja" }
          },
          required: ["query"]
        )

        class << self
          def call(query:, server_context:, locale: "ja") # rubocop:disable Lint/UnusedMethodArgument
            results = CopyTunerClient.cache.blurbs
              .select { |key, value| key.start_with?("#{locale}.") && value.include?(query) }
              .transform_keys { |key| key.split(".", 2).last }

            MCP::Tool::Response.new([{
              type: "text",
              text: JSON.pretty_generate(results)
            }], error: results.empty?)
          end
        end
      end
    end
  end
end
