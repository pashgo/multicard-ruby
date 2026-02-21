# frozen_string_literal: true

RSpec.describe Multicard::Resources::Cards do
  let(:client) { build_client }
  let(:base_url) { Multicard::TestHelpers::BASE_URL }

  before { stub_token_request }

  describe '#create_binding_link' do
    it 'creates a card binding link' do
      stub_api(:post, '/card/bind/session', body: fixture_json('binding_link')[:data])

      response = client.cards.create_binding_link
      expect(response.data[:session_id]).to eq('session-abc-123')
      expect(response.data[:url]).to include('card/bind')
    end
  end

  describe '#binding_status' do
    it 'checks binding status' do
      stub_api(:get, '/card/bind/status/session-abc-123',
               body: { status: 'bound', token: 'card_token_xyz' })

      response = client.cards.binding_status('session-abc-123')
      expect(response.data[:status]).to eq('bound')
      expect(response.data[:token]).to eq('card_token_xyz')
    end
  end

  describe '#add' do
    it 'sends OTP for card binding' do
      stub_api(:post, '/card/add', body: { message: 'SMS sent' })

      response = client.cards.add(card_number: '8600123456781234', card_expiry: '1228')
      expect(response.success?).to be true
    end
  end

  describe '#confirm_binding' do
    it 'confirms binding with OTP' do
      stub_api(:post, '/card/bind/confirm', body: fixture_json('card_bound')[:data])

      response = client.cards.confirm_binding(otp_code: '123456')
      expect(response.data[:token]).to eq('card_token_xyz')
    end
  end

  describe '#retrieve' do
    it 'gets card info by token' do
      stub_api(:get, '/card/card_token_xyz', body: fixture_json('card_bound')[:data])

      response = client.cards.retrieve('card_token_xyz')
      expect(response.data[:pan]).to eq('8600****5678')
      expect(response.data[:card_type]).to eq('uzcard')
    end
  end

  describe '#check' do
    it 'checks card number' do
      stub_api(:get, '/card/check/8600123456781234',
               body: { card_type: 'uzcard', valid: true })

      response = client.cards.check('8600123456781234')
      expect(response.data[:valid]).to be true
    end
  end

  describe '#verify_pinfl' do
    it 'verifies card ownership' do
      stub_api(:post, '/card/verify/pinfl', body: { verified: true })

      response = client.cards.verify_pinfl(token: 'tok', pinfl: '12345678901234')
      expect(response.data[:verified]).to be true
    end
  end

  describe '#revoke' do
    it 'revokes a card token' do
      stub_api(:delete, '/card/card_token_xyz', body: { revoked: true })

      response = client.cards.revoke('card_token_xyz')
      expect(response.data[:revoked]).to be true
    end
  end
end
