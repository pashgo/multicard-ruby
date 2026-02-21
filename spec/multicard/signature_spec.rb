# frozen_string_literal: true

require 'digest'

RSpec.describe Multicard::Signature do
  let(:secret) { 'test_secret_key' }

  let(:valid_params) do
    store_id = '100'
    invoice_id = 'ORD-001'
    amount = '500000'
    sign = Digest::MD5.hexdigest("#{store_id}#{invoice_id}#{amount}#{secret}")
    { store_id: store_id, invoice_id: invoice_id, amount: amount, sign: sign }
  end

  describe '.verify' do
    it 'returns true for valid signature' do
      expect(described_class.verify(valid_params, secret: secret)).to be true
    end

    it 'returns false for invalid signature' do
      params = valid_params.merge(sign: 'invalid_signature_hash')
      expect(described_class.verify(params, secret: secret)).to be false
    end

    it 'returns false for empty sign' do
      params = valid_params.merge(sign: '')
      expect(described_class.verify(params, secret: secret)).to be false
    end

    it 'returns false for wrong secret' do
      expect(described_class.verify(valid_params, secret: 'wrong_secret')).to be false
    end

    it 'handles trailing .0 in amount' do
      store_id = '100'
      invoice_id = 'ORD-002'
      amount_clean = '500000'
      sign = Digest::MD5.hexdigest("#{store_id}#{invoice_id}#{amount_clean}#{secret}")

      params = { store_id: store_id, invoice_id: invoice_id, amount: '500000.0', sign: sign }
      expect(described_class.verify(params, secret: secret)).to be true
    end

    it 'handles trailing .00 in amount' do
      store_id = '100'
      invoice_id = 'ORD-002'
      amount_clean = '500000'
      sign = Digest::MD5.hexdigest("#{store_id}#{invoice_id}#{amount_clean}#{secret}")

      params = { store_id: store_id, invoice_id: invoice_id, amount: '500000.00', sign: sign }
      expect(described_class.verify(params, secret: secret)).to be true
    end

    it 'does not strip non-.0 decimals' do
      store_id = '100'
      invoice_id = 'ORD-003'
      amount = '500000.5'
      sign = Digest::MD5.hexdigest("#{store_id}#{invoice_id}#{amount}#{secret}")

      params = { store_id: store_id, invoice_id: invoice_id, amount: amount, sign: sign }
      expect(described_class.verify(params, secret: secret)).to be true
    end

    it 'is case-insensitive for signatures' do
      params = valid_params.merge(sign: valid_params[:sign].upcase)
      expect(described_class.verify(params, secret: secret)).to be true
    end

    it 'handles integer store_id and amount' do
      store_id = 100
      invoice_id = 'ORD-004'
      amount = 500_000
      sign = Digest::MD5.hexdigest("#{store_id}#{invoice_id}#{amount}#{secret}")

      params = { store_id: store_id, invoice_id: invoice_id, amount: amount, sign: sign }
      expect(described_class.verify(params, secret: secret)).to be true
    end
  end
end
