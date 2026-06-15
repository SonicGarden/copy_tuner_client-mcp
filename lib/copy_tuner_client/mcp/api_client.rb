# frozen_string_literal: true

require "net/http"
require "net/https"
require "json"
require "cgi"
require "uri"
require "copy_tuner_client/mcp"

module CopyTunerClient
  module Mcp
    # CopyTuner OpenAPI v3 API (/api/v3) 向けの薄い HTTP クライアント。
    #
    # 接続設定および API キーはジェムの公開インターフェース
    # +CopyTunerClient.configuration+ から読み込む。標準ライブラリの Net::HTTP のみを
    # 使用しており、追加の依存関係は導入しない。
    class ApiClient
      API_BASE_PATH = "/api/v3"
      USER_AGENT = "copy_tuner_client-mcp #{CopyTunerClient::Mcp::VERSION}".freeze

      # Net::HTTP が発生させる例外のうち、ApiError に変換されるもの。
      HTTP_ERRORS = [
        Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
        SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED
      ].freeze

      # 1 件以上のドラフト blurb をローカライズデータとともに一括作成する。
      # @param blurbs [Array<Hash>] e.g. [{ key:, localizations: { "ja" => "..." } }]
      # @return [Hash] parsed response body
      # @raise [ApiError] on a non-success response
      def create_bulk_draft_blurbs(blurbs)
        request(Net::HTTP::Post.new("#{API_BASE_PATH}/bulk_draft_blurbs"), { blurbs: blurbs })
      end

      # 既存の blurb のドラフトローカライズデータを更新する。
      # @param key [String] the i18n key
      # @param localizations [Hash] e.g. { "ja" => "..." }
      # @return [Hash] parsed response body
      # @raise [ApiError] on a non-success response
      def update_draft_blurb(key, localizations)
        path = "#{API_BASE_PATH}/draft_blurbs/#{CGI.escape(key)}"
        request(Net::HTTP::Patch.new(path), { blurb: { localizations: localizations } })
      end

      private

      def request(http_request, body)
        http_request["Authorization"] = "Bearer #{configuration.api_key}"
        http_request["Content-Type"] = "application/json"
        http_request["User-Agent"] = USER_AGENT
        http_request.body = body.to_json

        response = connect { |http| http.request(http_request) }
        handle(response)
      end

      def connect
        yield build_http
      rescue *HTTP_ERRORS => e
        raise ApiError, "#{e.class.name}: #{e.message}"
      end

      def build_http
        Net::HTTP.new(configuration.host, configuration.port).tap do |http|
          http.open_timeout = configuration.http_open_timeout
          http.read_timeout = configuration.http_read_timeout
          http.use_ssl = configuration.secure?
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_file = configuration.ca_file
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

      # v3 エラー形式から人間が読めるメッセージを組み立てる。
      #   { "error": "..." } または { "message": "...", "errors": ["...", ...] }
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
