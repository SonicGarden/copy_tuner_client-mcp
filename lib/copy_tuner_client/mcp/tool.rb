# frozen_string_literal: true

module CopyTunerClient
  module Mcp
    # すべての MCP ツールの基底モジュール
    module Tool
    end
  end
end

Dir[File.join(__dir__, "tool", "*.rb")].each { |file| require file }
