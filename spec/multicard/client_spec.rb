# frozen_string_literal: true

RSpec.describe Multicard::Client do
  describe '#initialize' do
    before { stub_token_request }

    it 'creates a client with explicit config' do
      client = described_class.new(application_id: 'app', secret: 'secret')
      expect(client.config.application_id).to eq('app')
    end

    it 'merges global config with per-client overrides' do
      Multicard.configure do |c|
        c.application_id = 'global_app'
        c.secret = 'global_secret'
        c.store_id = 1
      end

      client = described_class.new(store_id: 99)
      expect(client.config.application_id).to eq('global_app')
      expect(client.config.store_id).to eq(99)
    end

    it 'raises without required credentials' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe 'resource accessors' do
    before { stub_token_request }

    let(:client) { build_client }

    it 'returns Invoices resource' do
      expect(client.invoices).to be_a(Multicard::Resources::Invoices)
    end

    it 'returns Payments resource' do
      expect(client.payments).to be_a(Multicard::Resources::Payments)
    end

    it 'returns Cards resource' do
      expect(client.cards).to be_a(Multicard::Resources::Cards)
    end

    it 'returns Holds resource' do
      expect(client.holds).to be_a(Multicard::Resources::Holds)
    end

    it 'returns Payouts resource' do
      expect(client.payouts).to be_a(Multicard::Resources::Payouts)
    end

    it 'returns Registry resource' do
      expect(client.registry).to be_a(Multicard::Resources::Registry)
    end

    it 'memoizes resources' do
      expect(client.invoices).to equal(client.invoices)
    end
  end

  describe '#authenticated_request' do
    let(:client) { build_client }

    before { stub_token_request }

    it 'includes Bearer token in request' do
      stub_api(:get, '/payment/uuid-123', body: { uuid: 'uuid-123' })

      client.authenticated_request(:get, '/payment/uuid-123')

      expect(WebMock).to have_requested(:get, "#{Multicard::TestHelpers::BASE_URL}/payment/uuid-123")
        .with(headers: { 'Authorization' => 'Bearer test_token_abc' })
    end

    it 'retries once on 401 with fresh token' do
      token_stub = stub_request(:post, "#{Multicard::TestHelpers::BASE_URL}/auth")
                   .to_return(
                     { status: 200, body: { token: 'token_1' }.to_json,
                       headers: { 'Content-Type' => 'application/json' } },
                     { status: 200, body: { token: 'token_2' }.to_json,
                       headers: { 'Content-Type' => 'application/json' } }
                   )

      error_body = { success: false, error: { code: 'UNAUTHORIZED', details: 'Token expired' } }
      ok_body = { success: true, data: { ok: true } }

      api_stub = stub_request(:get, "#{Multicard::TestHelpers::BASE_URL}/test")
                 .to_return(
                   { status: 401, body: error_body.to_json,
                     headers: { 'Content-Type' => 'application/json' } },
                   { status: 200, body: ok_body.to_json,
                     headers: { 'Content-Type' => 'application/json' } }
                 )

      response = client.authenticated_request(:get, '/test')
      expect(response.data[:ok]).to be true
      expect(token_stub).to have_been_requested.twice
      expect(api_stub).to have_been_requested.twice
    end
  end
end
