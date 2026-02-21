# frozen_string_literal: true

RSpec.describe Multicard::TokenManager do
  let(:config) do
    Multicard::Configuration.new(application_id: 'app_123', secret: 'secret_456')
  end
  let(:http_client) { Multicard::HttpClient.new(config) }
  let(:manager) { described_class.new(http_client, config) }
  let(:base_url) { Multicard::TestHelpers::BASE_URL }

  describe '#token' do
    it 'fetches token on first call' do
      stub_request(:post, "#{base_url}/auth")
        .with(body: { application_id: 'app_123', secret: 'secret_456' })
        .to_return(status: 200,
                   body: { token: 'fresh_token' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(manager.token).to eq('fresh_token')
    end

    it 'caches token on subsequent calls' do
      stub = stub_request(:post, "#{base_url}/auth")
             .to_return(status: 200,
                        body: { token: 'cached_token' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      3.times { manager.token }
      expect(stub).to have_been_requested.once
    end

    it 'refreshes when expired' do
      stub_request(:post, "#{base_url}/auth")
        .to_return(
          { status: 200, body: { token: 'token_1' }.to_json,
            headers: { 'Content-Type' => 'application/json' } },
          { status: 200, body: { token: 'token_2' }.to_json,
            headers: { 'Content-Type' => 'application/json' } }
        )

      manager.token # first fetch
      # Simulate expiry
      manager.instance_variable_set(:@expires_at, Time.now - 1)
      expect(manager.token).to eq('token_2')
    end

    it 'raises AuthenticationError when response has no token' do
      stub_request(:post, "#{base_url}/auth")
        .to_return(status: 200,
                   body: {}.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { manager.token }.to raise_error(Multicard::AuthenticationError, /missing token/)
    end
  end

  describe '#expired? (private)' do
    it 'returns true when no token' do
      expect(manager.send(:expired?)).to be true
    end

    it 'returns false with valid token' do
      stub_request(:post, "#{base_url}/auth")
        .to_return(status: 200,
                   body: { token: 't' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      manager.token
      expect(manager.send(:expired?)).to be false
    end
  end

  describe '#reset!' do
    it 'clears cached token' do
      stub = stub_request(:post, "#{base_url}/auth")
             .to_return(status: 200,
                        body: { token: 't' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      manager.token
      manager.reset!
      manager.token

      expect(stub).to have_been_requested.twice
    end
  end
end
