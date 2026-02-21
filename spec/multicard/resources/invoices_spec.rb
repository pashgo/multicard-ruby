# frozen_string_literal: true

RSpec.describe Multicard::Resources::Invoices do
  let(:client) { build_client }
  let(:base_url) { Multicard::TestHelpers::BASE_URL }

  before { stub_token_request }

  describe '#create' do
    it 'creates an invoice' do
      stub_api(:post, '/payment/invoice', body: fixture_json('invoice_created')[:data])

      response = client.invoices.create(
        amount: 500_000,
        invoice_id: 'ORD-001',
        callback_url: 'https://example.com/webhooks'
      )

      expect(response.data[:checkout_url]).to include('checkout.multicard.uz')
      expect(response.data[:uuid]).to eq('inv-uuid-123')
    end

    it 'uses default store_id from config' do
      stub_api(:post, '/payment/invoice', body: {})

      client.invoices.create(
        amount: 100_000,
        invoice_id: 'ORD-002',
        callback_url: 'https://example.com/cb'
      )

      expect(WebMock).to have_requested(:post, "#{base_url}/payment/invoice")
        .with(body: hash_including(store_id: 100))
    end

    it 'allows overriding store_id' do
      stub_api(:post, '/payment/invoice', body: {})

      client.invoices.create(
        amount: 100_000,
        invoice_id: 'ORD-003',
        callback_url: 'https://example.com/cb',
        store_id: 999
      )

      expect(WebMock).to have_requested(:post, "#{base_url}/payment/invoice")
        .with(body: hash_including(store_id: 999))
    end

    it 'passes extra options' do
      stub_api(:post, '/payment/invoice', body: {})

      client.invoices.create(
        amount: 100_000,
        invoice_id: 'ORD-004',
        callback_url: 'https://example.com/cb',
        description: 'Test payment',
        lifetime: 3600
      )

      expect(WebMock).to have_requested(:post, "#{base_url}/payment/invoice")
        .with(body: hash_including(description: 'Test payment', lifetime: 3600))
    end
  end

  describe '#retrieve' do
    it 'retrieves invoice info' do
      stub_api(:get, '/invoice/inv-123', body: { uuid: 'inv-123', status: 'paid' })

      response = client.invoices.retrieve('inv-123')
      expect(response.data[:status]).to eq('paid')
    end
  end

  describe '#cancel' do
    it 'cancels an invoice' do
      stub_api(:delete, '/invoice/inv-123', body: { uuid: 'inv-123', status: 'cancelled' })

      response = client.invoices.cancel('inv-123')
      expect(response.success?).to be true
    end
  end

  describe '#quick_pay' do
    it 'generates a quick pay link' do
      stub_api(:post, '/invoice/quick-pay', body: { url: 'https://payme.uz/pay/abc' })

      response = client.invoices.quick_pay(invoice_id: 'inv-123', service: 'payme')
      expect(response.data[:url]).to include('payme.uz')
    end
  end
end
