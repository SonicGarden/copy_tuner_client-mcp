# frozen_string_literal: true

require "mcp"
require "copy_tuner_client/mcp"

module CopyTunerClient
  module Mcp
    module Tool
      # i18n 書き込みツール共通のヘルパー: 翻訳データの変換、API エラーハンドリング、
      # テキスト形式の MCP::Tool::Response 構築を提供する。
      module ResponseHelpers
        # 反映待ちポーリングのタイムアウト（秒）と間隔（秒）。
        # 反映経路は API → S3 → CloudFront → cache.download で数秒〜十数秒かかるため、
        # 間隔は CloudFront のキャッシュスケールに合わせて広めに取る（短くしても反映は早まらない）。
        CACHE_WAIT_TIMEOUT = 120
        CACHE_WAIT_INTERVAL = 5

        # ツールの `translations` 配列を CopyTuner のローカライズハッシュに変換し、
        # ブロック（API 呼び出しを実施）に yield して、結果または ApiError を
        # MCP::Tool::Response にラップして返す。
        #
        # @param verb [String] past-tense action for the success message (e.g. "Created")
        # @param wait [Boolean] true のとき、書き込んだ値が CopyTunerClient.cache に
        #   反映される（S3 ダウンロードで blurbs / blank_keys の値が書き込んだ値と一致する）まで
        #   最大 CACHE_WAIT_TIMEOUT 秒ポーリングしてから成功レスポンスを返す。
        def run_i18n_tool(key:, translations:, verb:, wait: false)
          localizations = translations.to_h { |t| [t[:locale], t[:value]] }

          yield localizations

          message = "#{verb} i18n key #{key}. (locales: #{localizations.keys.join(", ")})"
          message += cache_reflection_note(key, localizations) if wait
          success_response(message)
        rescue CopyTunerClient::Mcp::ApiError => e
          error_response("Failed to #{verb.downcase} i18n key #{key}: #{e.message}")
        end

        def success_response(text)
          MCP::Tool::Response.new([{ type: "text", text: text }])
        end

        def error_response(text)
          MCP::Tool::Response.new([{ type: "text", text: text }], error: true)
        end

        private

        # 反映を待ち、結果を成功メッセージへ付記する一文を返す。
        def cache_reflection_note(key, localizations)
          if wait_for_cache_reflection(key: key, localizations: localizations)
            " Confirmed in cache."
          else
            " (cache reflection not confirmed within #{CACHE_WAIT_TIMEOUT}s; " \
              "draft may still be propagating, or this project downloads published content only.)"
          end
        end

        # 書き込んだ値が cache に反映されるまで cache.download を繰り返す。
        # いずれかの locale の値が一致したら true、タイムアウトで false。
        # （一括登録・更新は CopyTuner 側で同時に反映されるため、1 つ確認できれば十分）
        def wait_for_cache_reflection(key:, localizations:)
          deadline = monotonic_time + CACHE_WAIT_TIMEOUT

          loop do
            refresh_cache
            return true if reflected?(key, localizations)
            return false if monotonic_time >= deadline

            sleep CACHE_WAIT_INTERVAL
          end
        end

        def reflected?(key, localizations)
          cache = CopyTunerClient.cache
          blurbs = cache.blurbs
          blank_keys = cache.blank_keys
          localizations.any? do |locale, value|
            locale_key = "#{locale}.#{key}"
            value.to_s.empty? ? blank_keys.include?(locale_key) : blurbs[locale_key] == value
          end
        end

        # 最新の翻訳を S3 から取得して cache を更新する。
        # 接続エラーは致命的でないため握りつぶし、タイムアウト判定に委ねる。
        def refresh_cache
          CopyTunerClient.cache.download
        rescue CopyTunerClient::ConnectionError
          nil
        end

        def monotonic_time
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end
    end
  end
end
