# frozen_string_literal: true

require "mcp"
require "copy_tuner_client/mcp"

module CopyTunerClient
  module Mcp
    module Tool
      # Shared helpers for i18n write tools: translation conversion, API error
      # handling, and text MCP::Tool::Response construction.
      module ResponseHelpers
        # Converts the tool's `translations` array into a CopyTuner localizations
        # hash, yields it to the block (which performs the API call), and wraps
        # the result — or any ApiError — into an MCP::Tool::Response.
        #
        # @param verb [String] past-tense action for the success message (e.g. "Created")
        # @param failed_verb [String] action for the error message (e.g. "create")
        def run_i18n_tool(key:, translations:, verb:, failed_verb:)
          localizations = translations.to_h { |t| [t[:locale], t[:value]] }

          yield localizations

          success_response("#{verb} i18n key #{key}. (locales: #{localizations.keys.join(", ")})")
        rescue CopyTunerClient::Mcp::ApiError => e
          error_response("Failed to #{failed_verb} i18n key #{key}: #{e.message}")
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
