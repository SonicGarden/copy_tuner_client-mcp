# frozen_string_literal: true

require "copy_tuner_client/mcp/tool/get_locales"

RSpec.describe CopyTunerClient::Mcp::Tool::GetLocales do
  describe ".call" do
    let(:server_context) { double("server_context") }
    let(:mock_configuration) { double("configuration", locales: %w[ja en fr]) }

    before do
      allow(CopyTunerClient).to receive(:configuration).and_return(mock_configuration)
    end

    it "returns the list of configured locales" do
      response = described_class.call(server_context: server_context)

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.error?).to be(false)
      expect(response.content.first[:type]).to eq("text")

      result = JSON.parse(response.content.first[:text])
      expect(result).to eq({ "locales" => %w[ja en fr] })
    end

    it "handles empty locales list" do
      allow(mock_configuration).to receive(:locales).and_return([])

      response = described_class.call(server_context: server_context)

      expect(response).to be_a(MCP::Tool::Response)
      result = JSON.parse(response.content.first[:text])
      expect(result).to eq({ "locales" => [] })
    end
  end
end
