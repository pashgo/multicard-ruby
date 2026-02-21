# frozen_string_literal: true

RSpec.describe Multicard::Resources::Payouts do
  let(:client) { build_client }
  let(:base_url) { Multicard::TestHelpers::BASE_URL }

  before { stub_token_request }

  describe '#create' do
    it 'creates a payout' do
      stub_api(:post, '/payout', body: fixture_json('payout_created')[:data])

      response = client.payouts.create(card_number: '8600999988887777', amount: 100_000)
      expect(response.data[:id]).to eq('payout-id-101')
      expect(response.data[:amount]).to eq(100_000)
    end
  end

  describe '#confirm' do
    it 'confirms a payout' do
      stub_api(:post, '/payout/payout-id-101/confirm', body: { status: 'confirmed' })

      response = client.payouts.confirm('payout-id-101')
      expect(response.data[:status]).to eq('confirmed')
    end
  end

  describe '#retrieve' do
    it 'retrieves payout info' do
      stub_api(:get, '/payout/payout-id-101', body: fixture_json('payout_created')[:data])

      response = client.payouts.retrieve('payout-id-101')
      expect(response.data[:id]).to eq('payout-id-101')
    end
  end
end
