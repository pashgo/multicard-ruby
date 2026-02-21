# frozen_string_literal: true

RSpec.describe Multicard::Resources::Payments do
  let(:client) { build_client }
  let(:base_url) { Multicard::TestHelpers::BASE_URL }

  before { stub_token_request }

  describe '#create_by_token' do
    it 'creates a payment by card token' do
      stub_api(:post, '/payment/token', body: fixture_json('payment_success')[:data])

      response = client.payments.create_by_token(
        card_token: 'token_abc',
        amount: 500_000,
        invoice_id: 'ORD-001'
      )

      expect(response.data[:uuid]).to eq('pay-uuid-456')
      expect(response.data[:status]).to eq('confirmed')
    end

    it 'sends correct body structure' do
      stub_api(:post, '/payment/token', body: {})

      client.payments.create_by_token(
        card_token: 'tok_xyz',
        amount: 100_000,
        invoice_id: 'ORD-002',
        callback_url: 'https://example.com/cb'
      )

      expect(WebMock).to have_requested(:post, "#{base_url}/payment/token")
        .with(body: hash_including(
          card: { token: 'tok_xyz' },
          amount: 100_000,
          store_id: 100,
          invoice_id: 'ORD-002',
          callback_url: 'https://example.com/cb'
        ))
    end

    it 'raises InsufficientFundsError' do
      stub_request(:post, "#{base_url}/payment/token")
        .to_return(status: 400, body: fixture('payment_error'),
                   headers: { 'Content-Type' => 'application/json' })

      expect do
        client.payments.create_by_token(card_token: 't', amount: 999, invoice_id: 'X')
      end.to raise_error(Multicard::InsufficientFundsError)
    end
  end

  describe '#create_by_card' do
    it 'creates a payment by card number' do
      stub_api(:post, '/payment/card', body: { uuid: 'p-1' })

      response = client.payments.create_by_card(
        card_number: '8600123456781234',
        card_expiry: '1228',
        amount: 200_000,
        invoice_id: 'ORD-003'
      )

      expect(response.data[:uuid]).to eq('p-1')
    end
  end

  describe '#create_split' do
    it 'creates a split payment' do
      stub_api(:post, '/payment/split', body: { uuid: 'split-1' })

      split = [
        { type: 'account', amount: 400_000, details: 'Store share', recipient: 'uuid-1' },
        { type: 'wallet', amount: 100_000, details: 'Platform fee' }
      ]

      response = client.payments.create_split(
        card_token: 'tok_abc',
        amount: 500_000,
        invoice_id: 'ORD-004',
        split: split
      )

      expect(response.data[:uuid]).to eq('split-1')
      expect(WebMock).to have_requested(:post, "#{base_url}/payment/split")
        .with(body: hash_including(split: split))
    end
  end

  describe '#create_wallet' do
    it 'creates a wallet payment' do
      stub_api(:post, '/payment/app', body: { uuid: 'w-1' })

      response = client.payments.create_wallet(
        service: 'payme',
        amount: 300_000,
        invoice_id: 'ORD-005'
      )

      expect(response.data[:uuid]).to eq('w-1')
    end
  end

  describe '#confirm' do
    it 'confirms a payment with OTP' do
      stub_api(:post, '/payment/pay-1/confirm', body: { status: 'confirmed' })

      response = client.payments.confirm('pay-1', otp_code: '123456')
      expect(response.data[:status]).to eq('confirmed')
    end

    it 'confirms without OTP' do
      stub_api(:post, '/payment/pay-1/confirm', body: { status: 'confirmed' })

      client.payments.confirm('pay-1')
      expect(WebMock).to have_requested(:post, "#{base_url}/payment/pay-1/confirm")
        .with(body: {})
    end
  end

  describe '#retrieve' do
    it 'retrieves payment info' do
      stub_api(:get, '/payment/pay-1', body: fixture_json('payment_success')[:data])

      response = client.payments.retrieve('pay-1')
      expect(response.data[:uuid]).to eq('pay-uuid-456')
    end
  end

  describe '#refund' do
    it 'refunds a payment' do
      stub_api(:delete, '/payment/pay-1', body: { status: 'refunded' })

      response = client.payments.refund('pay-1')
      expect(response.data[:status]).to eq('refunded')
    end
  end

  describe '#partial_refund' do
    it 'partially refunds a payment' do
      stub_api(:post, '/payment/pay-1/refund/partial', body: { status: 'partially_refunded' })

      client.payments.partial_refund('pay-1', amount: 100_000)
      expect(WebMock).to have_requested(:post, "#{base_url}/payment/pay-1/refund/partial")
        .with(body: { amount: 100_000 })
    end
  end

  describe '#send_fiscal_link' do
    it 'sends a fiscal receipt link' do
      stub_api(:post, '/payment/pay-1/fiscal', body: {})

      client.payments.send_fiscal_link('pay-1', fiscal_url: 'https://ofd.uz/receipt/123')
      expect(WebMock).to have_requested(:post, "#{base_url}/payment/pay-1/fiscal")
        .with(body: { fiscal_url: 'https://ofd.uz/receipt/123' })
    end
  end
end
