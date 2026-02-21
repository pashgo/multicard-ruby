# frozen_string_literal: true

RSpec.describe Multicard::Resources::Holds do
  let(:client) { build_client }
  let(:base_url) { Multicard::TestHelpers::BASE_URL }

  before { stub_token_request }

  describe '#create' do
    it 'creates a hold' do
      stub_api(:post, '/hold', body: fixture_json('hold_created')[:data])

      response = client.holds.create(
        card_token: 'tok_abc',
        amount: 500_000,
        invoice_id: 'HOLD-001'
      )

      expect(response.data[:id]).to eq('hold-id-789')
      expect(response.data[:status]).to eq('created')
    end

    it 'uses default store_id' do
      stub_api(:post, '/hold', body: {})

      client.holds.create(card_token: 'tok', amount: 100, invoice_id: 'H-1')

      expect(WebMock).to have_requested(:post, "#{base_url}/hold")
        .with(body: hash_including(store_id: 100))
    end
  end

  describe '#confirm' do
    it 'confirms a hold with OTP' do
      stub_api(:post, '/hold/hold-id-789/confirm', body: fixture_json('hold_confirmed')[:data])

      response = client.holds.confirm('hold-id-789', otp_code: '123456')
      expect(response.data[:status]).to eq('confirmed')
    end

    it 'confirms without OTP' do
      stub_api(:post, '/hold/hold-id-789/confirm', body: {})

      client.holds.confirm('hold-id-789')
      expect(WebMock).to have_requested(:post, "#{base_url}/hold/hold-id-789/confirm")
        .with(body: {})
    end
  end

  describe '#capture' do
    it 'captures full amount' do
      stub_api(:post, '/hold/hold-id-789/charge', body: { status: 'debited' })

      response = client.holds.capture('hold-id-789')
      expect(response.data[:status]).to eq('debited')
    end

    it 'captures partial amount' do
      stub_api(:post, '/hold/hold-id-789/charge', body: { status: 'debited', amount: 300_000 })

      client.holds.capture('hold-id-789', amount: 300_000)
      expect(WebMock).to have_requested(:post, "#{base_url}/hold/hold-id-789/charge")
        .with(body: { amount: 300_000 })
    end
  end

  describe '#retrieve' do
    it 'retrieves hold info' do
      stub_api(:get, '/hold/hold-id-789', body: fixture_json('hold_created')[:data])

      response = client.holds.retrieve('hold-id-789')
      expect(response.data[:id]).to eq('hold-id-789')
    end
  end

  describe '#cancel' do
    it 'cancels a hold' do
      stub_api(:delete, '/hold/hold-id-789', body: { status: 'cancelled' })

      response = client.holds.cancel('hold-id-789')
      expect(response.data[:status]).to eq('cancelled')
    end
  end
end
