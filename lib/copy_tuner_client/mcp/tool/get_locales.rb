# frozen_string_literal: true

require "mcp"
require "json"

module CopyTunerClient
  module Mcp
    module Tool
      # NOTE: Resourceとして定義するほうが適切な気がするが、MCPクライアントがうまく参照してくれないためToolとして定義している
      class GetLocales < MCP::Tool
        tool_name "get_locales"
        description "Retrieve the list of Rails i18n locales currently in use in the copy_tuner project. This tool provides a quick way to see which Rails i18n locales have been registered and are actively used in translations."

        class << self
          def call(server_context:) # rubocop:disable Lint/UnusedMethodArgument
            locales = CopyTunerClient.configuration.locales

            MCP::Tool::Response.new([{
              type: "text",
              text: JSON.pretty_generate({ locales: })
            }])
          end
        end
      end
    end
  end
end
