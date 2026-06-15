# frozen_string_literal: true

require "mcp"
require "json"

module CopyTunerClient
  module Mcp
    module Tool
      class SearchKey < MCP::Tool
        tool_name "search_key"
        description "Search and retrieve Rails i18n translation keys. Optimized for finding keys used " \
                    "with t() or I18n.t(), checking whether a key already exists, and getting locale-specific " \
                    "translation values. Returns BOTH translated keys and registered-but-empty keys; an empty " \
                    "string value (\"\") means the key already exists but has no translation yet. If a key " \
                    "appears here it is already registered, so use update_i18n_key (not create_i18n_key) to " \
                    "set its translation. Quickly finds accurate keys from the copy_tuner project translation database."
        input_schema(
          properties: {
            query: { type: "string" },
            locale: { type: "string", default: "ja" }
          },
          required: ["query"]
        )

        class << self
          def call(query:, server_context:, locale: "ja") # rubocop:disable Lint/UnusedMethodArgument
            results = search(query, locale)

            MCP::Tool::Response.new([{
              type: "text",
              text: JSON.pretty_generate(results)
            }], error: results.empty?)
          end

          private

          def search(query, locale)
            matcher = ->(key) { key.start_with?("#{locale}.") && key.include?(query) }
            cache = CopyTunerClient.cache

            # 翻訳が空のキー（blank_keys）も「登録済み」として "" 付きで返し、
            # AI が create ではなく update を選べるようにする。同名キーは翻訳済みを優先。
            blank_matches(cache, matcher).merge(translated_matches(cache, matcher))
          end

          def translated_matches(cache, matcher)
            cache.blurbs
              .select { |key, _| matcher.call(key) }
              .transform_keys { |key| strip_locale(key) }
          end

          def blank_matches(cache, matcher)
            cache.blank_keys
              .select { |key| matcher.call(key) }
              .to_h { |key| [strip_locale(key), ""] }
          end

          def strip_locale(key)
            key.split(".", 2).last
          end
        end
      end
    end
  end
end
