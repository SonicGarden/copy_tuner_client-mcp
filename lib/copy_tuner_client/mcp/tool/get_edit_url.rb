# frozen_string_literal: true

require "mcp"
require "json"

module CopyTunerClient
  module Mcp
    module Tool
      # 登録済みキーの編集画面のURLを取得
      class GetEditUrl < MCP::Tool
        tool_name "get_edit_url"
        description "Retrieve the edit URL for a registered i18n key in the copy_tuner project."
        input_schema(
          properties: {
            key: { type: "string", description: "The i18n key to retrieve the edit URL for" }
          },
          required: ["key"]
        )

        class << self
          def call(key:, server_context:) # rubocop:disable Lint/UnusedMethodArgument
            edit_url = "#{CopyTunerClient.configuration.project_url}/blurbs/#{key}/edit"

            MCP::Tool::Response.new([{
              type: "text",
              text: edit_url
            }])
          end
        end
      end
    end
  end
end
