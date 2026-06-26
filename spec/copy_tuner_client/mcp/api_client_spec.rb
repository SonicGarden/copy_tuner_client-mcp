# frozen_string_literal: true

require "copy_tuner_client/mcp/api_client"

RSpec.describe CopyTunerClient::Mcp::ApiClient do
  let(:configuration) do
    instance_double(
      "CopyTunerClient::Configuration",
      api_key: "test-api-key",
      host: "copy-tuner.example.com",
      port: 443,
      secure?: true,
      protocol: "https",
      ca_file: nil,
      http_open_timeout: 5,
      http_read_timeout: 5
    )
  end

  let(:http) { instance_double(Net::HTTP) }

  before do
    allow(CopyTunerClient).to receive(:configuration).and_return(configuration)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:verify_mode=)
    allow(http).to receive(:ca_file=)
  end

  def stub_response(klass, body)
    response = instance_double(klass, body: body)
    allow(response).to receive(:is_a?) { |c| klass <= c }
    response
  end

  describe "#create_sync_bulk_draft_blurbs" do
    let(:blurbs) do
      [{ key: "greeting.hello", localizations: { "ja" => "こんにちは", "en" => "Hello" } }]
    end

    it "bearer 認証と JSON ボディで /api/v3/sync_bulk_draft_blurbs に POST する" do
      captured = {}
      allow(http).to receive(:request) do |request|
        captured[:method] = request.method
        captured[:path] = request.path
        captured[:authorization] = request["Authorization"]
        captured[:content_type] = request["Content-Type"]
        captured[:body] = request.body
        stub_response(Net::HTTPCreated, '{"message":"Draft blurbs created successfully"}')
      end

      result = described_class.new.create_sync_bulk_draft_blurbs(blurbs)

      expect(captured[:method]).to eq("POST")
      expect(captured[:path]).to eq("/api/v3/sync_bulk_draft_blurbs")
      expect(captured[:authorization]).to eq("Bearer test-api-key")
      expect(captured[:content_type]).to eq("application/json")
      expect(JSON.parse(captured[:body])).to eq(
        "blurbs" => [
          { "key" => "greeting.hello", "localizations" => { "ja" => "こんにちは", "en" => "Hello" } }
        ]
      )
      expect(result["message"]).to eq("Draft blurbs created successfully")
    end

    it "422 のとき message と errors 配列を含む ApiError を raise する" do
      body = '{"message":"Failed to create draft blurbs.",' \
             '"errors":["Blurb \'greeting.hello\' already exists."]}'
      allow(http).to receive(:request).and_return(
        stub_response(Net::HTTPUnprocessableEntity, body)
      )

      expect { described_class.new.create_sync_bulk_draft_blurbs(blurbs) }
        .to raise_error(
          CopyTunerClient::Mcp::ApiError,
          /Failed to create draft blurbs\..*Blurb 'greeting\.hello' already exists\./
        )
    end

    it "401 のとき ApiError を raise する" do
      allow(http).to receive(:request).and_return(
        stub_response(Net::HTTPUnauthorized, '{"error":"Invalid API key."}')
      )

      expect { described_class.new.create_sync_bulk_draft_blurbs(blurbs) }
        .to raise_error(CopyTunerClient::Mcp::ApiError, /Invalid API key\./)
    end
  end

  describe "#update_draft_blurb" do
    let(:localizations) { { "ja" => "こんにちは" } }

    it "エスケープ済みキーと blurb ボディで /api/v3/draft_blurbs/{key} に PATCH する" do
      captured = {}
      allow(http).to receive(:request) do |request|
        captured[:method] = request.method
        captured[:path] = request.path
        captured[:body] = request.body
        stub_response(Net::HTTPOK, '{"message":"Draft blurb localizations updated successfully"}')
      end

      result = described_class.new.update_draft_blurb("greeting.hello", localizations)

      expect(captured[:method]).to eq("PATCH")
      expect(captured[:path]).to eq("/api/v3/draft_blurbs/greeting.hello")
      expect(JSON.parse(captured[:body])).to eq(
        "blurb" => { "localizations" => { "ja" => "こんにちは" } }
      )
      expect(result["message"]).to eq("Draft blurb localizations updated successfully")
    end

    it "422 のとき errors 配列を ApiError のメッセージに含める" do
      body = '{"message":"Some translations cannot be updated.",' \
             '"errors":["Translation for locale \'en\' has been published and cannot be updated via API."]}'
      allow(http).to receive(:request).and_return(
        stub_response(Net::HTTPUnprocessableEntity, body)
      )

      expect { described_class.new.update_draft_blurb("greeting.hello", localizations) }
        .to raise_error(CopyTunerClient::Mcp::ApiError, /has been published and cannot be updated via API/)
    end
  end
end
