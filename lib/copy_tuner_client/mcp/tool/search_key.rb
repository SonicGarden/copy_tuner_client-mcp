# frozen_string_literal: true

require "mcp"
require "json"

module CopyTunerClient
  module Mcp
    module Tool
      class SearchKey < MCP::Tool
        tool_name "search_key"
        description "Search and retrieve Rails i18n translation keys. Optimized for finding keys used with t() or I18n.t(), checking multilingual translation content, and getting locale-specific translation values. Quickly finds accurate keys and translations from copy_tuner project translation database."
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
              .select { |key, _| key.start_with?("#{locale}.") && key.include?(query) }
              .transform_keys { |key| key.split(".", 2).last }

            MCP::Tool::Response.new([{
              type: "text",
              text: JSON.pretty_generate(results)
            }], results.empty?)
          end
        end
      end
    end
  end
end
