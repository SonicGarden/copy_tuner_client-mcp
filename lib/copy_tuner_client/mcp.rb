# frozen_string_literal: true

require_relative "mcp/version"
require_relative "mcp/tool"

module CopyTunerClient
  module Mcp
    class Error < StandardError; end

    # CopyTuner OpenAPI v3 サーバーが非成功レスポンスを返した場合に発生する。
    class ApiError < Error; end
  end
end
