# frozen_string_literal: true

require "copy_tuner_client/mcp/tool/get_edit_url"

RSpec.describe CopyTunerClient::Mcp::Tool::GetEditUrl do
  describe ".call" do
    let(:server_context) { double("server_context") }
    let(:key) { "test.key" }
    let(:project_url) { "https://copy-tuner.example.com" }
    let(:mock_configuration) { double("configuration", project_url: project_url) }

    before do
      allow(CopyTunerClient).to receive(:configuration).and_return(mock_configuration)
    end

    it "returns the edit URL for the given key" do
      response = described_class.call(key: key, server_context: server_context)

      expect(response).to be_a(MCP::Tool::Response)
      expect(response.is_error).to be(false)
      expect(response.content.first[:type]).to eq("text")

      expected_url = "#{project_url}/blurbs/#{key}/edit"
      expect(response.content.first[:text]).to eq(expected_url)
    end

    it "handles keys with special characters" do
      special_key = "test.key-with_special.chars"

      response = described_class.call(key: special_key, server_context: server_context)

      expected_url = "#{project_url}/blurbs/#{special_key}/edit"
      expect(response.content.first[:text]).to eq(expected_url)
    end
  end
end
