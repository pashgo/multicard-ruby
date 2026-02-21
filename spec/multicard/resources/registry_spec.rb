# frozen_string_literal: true

RSpec.describe Multicard::Resources::Registry do
  let(:client) { build_client }
  let(:base_url) { Multicard::TestHelpers::BASE_URL }

  before { stub_token_request }

  describe '#payments' do
    it 'fetches payment registry' do
      stub_request(:get, "#{base_url}/payments/registry")
        .with(query: { date_from: '2025-01-01', date_to: '2025-01-31' })
        .to_return(
          status: 200,
          body: { success: true, data: { items: [ { uuid: 'p1' } ], total: 1 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = client.registry.payments(date_from: '2025-01-01', date_to: '2025-01-31')
      expect(response.data[:items]).to be_an(Array)
      expect(response.data[:total]).to eq(1)
    end
  end

  describe '#payouts' do
    it 'fetches payout history' do
      stub_api(:get, '/payout/history', body: { items: [], total: 0 })

      response = client.registry.payouts
      expect(response.data[:items]).to eq([])
    end
  end

  describe '#application_info' do
    it 'fetches application info' do
      stub_api(:get, '/app/info', body: { name: 'Test App', balance: 1_000_000 })

      response = client.registry.application_info
      expect(response.data[:name]).to eq('Test App')
    end
  end

  describe '#merchant_details' do
    it 'fetches merchant banking details' do
      stub_api(:get, '/merchant/details', body: { inn: '123456789', name: 'LLC Test' })

      response = client.registry.merchant_details
      expect(response.data[:inn]).to eq('123456789')
    end
  end
end
