# frozen_string_literal: true

module CopyTunerClient
  module Mcp
    module Tool
      # Base module for all MCP tools
    end
  end
end

# Auto-require all tool files
Dir[File.join(__dir__, "tool", "*.rb")].each { |file| require file }
