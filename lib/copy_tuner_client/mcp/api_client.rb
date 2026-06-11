# frozen_string_literal: true

require "net/http"
require "net/https"
require "json"
require "cgi"
require "uri"
require "copy_tuner_client/mcp"

module CopyTunerClient
  module Mcp
    # Thin HTTP client for the CopyTuner OpenAPI v3 API (/api/v3).
    #
    # Connection settings and the API key are read from the gem's public
    # +CopyTunerClient.configuration+. Only Net::HTTP from the standard library
    # is used; no extra dependency is introduced.
    class ApiClient
      API_BASE_PATH = "/api/v3"
      USER_AGENT = "copy_tuner_client-mcp #{CopyTunerClient::Mcp::VERSION}".freeze

      # Errors raised by Net::HTTP that are translated into ApiError.
      HTTP_ERRORS = [
        Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
        SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED
      ].freeze

      # Creates one or more draft blurbs together with their localizations.
      # @param blurbs [Array<Hash>] e.g. [{ key:, localizations: { "ja" => "..." } }]
      # @return [Hash] parsed response body
      # @raise [ApiError] on a non-success response
      def create_bulk_draft_blurbs(blurbs)
        request(Net::HTTP::Post.new("#{API_BASE_PATH}/bulk_draft_blurbs"), { blurbs: blurbs })
      end

      # Updates the draft localizations of an existing blurb.
      # @param key [String] the i18n key
      # @param localizations [Hash] e.g. { "ja" => "..." }
      # @return [Hash] parsed response body
      # @raise [ApiError] on a non-success response
      def update_draft_blurb(key, localizations)
        path = "#{API_BASE_PATH}/draft_blurbs/#{CGI.escape(key)}"
        request(Net::HTTP::Patch.new(path), { blurb: { localizations: localizations } })
      end

      private

      def request(request, body)
        request["Authorization"] = "Bearer #{configuration.api_key}"
        request["Content-Type"] = "application/json"
        request["User-Agent"] = USER_AGENT
        request.body = body.to_json

        response = connect { |http| http.request(request) }
        handle(response)
      end

      def connect
        yield build_http
      rescue *HTTP_ERRORS => e
        raise ApiError, "#{e.class.name}: #{e.message}"
      end

      def build_http
        config = configuration
        Net::HTTP.new(config.host, config.port).tap do |http|
          http.open_timeout = config.http_open_timeout
          http.read_timeout = config.http_read_timeout
          http.use_ssl = config.secure?
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_file = config.ca_file
        end
      end

      def handle(response)
        body = parse_body(response.body)
        return body if response.is_a?(Net::HTTPSuccess)

        raise ApiError, error_message(body)
      end

      def parse_body(raw)
        return {} if raw.nil? || raw.empty?

        JSON.parse(raw)
      rescue JSON::ParserError
        { "error" => raw }
      end

      # Builds a human-readable message from the v3 error shapes:
      #   { "error": "..." } or { "message": "...", "errors": ["...", ...] }
      def error_message(body)
        return body.to_s unless body.is_a?(Hash)

        parts = [body["error"], body["message"]].compact
        parts.concat(Array(body["errors"]))
        parts.empty? ? "Unexpected error" : parts.join(" ")
      end

      def configuration
        CopyTunerClient.configuration
      end
    end
  end
end
