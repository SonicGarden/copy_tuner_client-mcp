# frozen_string_literal: true

require_relative "mcp/version"
require_relative "mcp/tool"

module CopyTunerClient
  module Mcp
    class Error < StandardError; end

    # Raised when the CopyTuner OpenAPI v3 server returns a non-success response.
    class ApiError < Error; end
  end
end
