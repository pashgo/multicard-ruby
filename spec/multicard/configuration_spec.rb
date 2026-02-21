# frozen_string_literal: true

RSpec.describe Multicard::Configuration do
  describe '#initialize' do
    it 'sets defaults' do
      config = described_class.new

      expect(config.base_url).to eq('https://api.multicard.uz')
      expect(config.timeout).to eq(30)
      expect(config.open_timeout).to eq(10)
      expect(config.logger).to be_nil
      expect(config.store_id).to be_nil
    end

    it 'accepts options' do
      config = described_class.new(
        application_id: 'app_123',
        secret: 'secret_456',
        base_url: 'https://custom.url',
        timeout: 60,
        store_id: 42
      )

      expect(config.application_id).to eq('app_123')
      expect(config.secret).to eq('secret_456')
      expect(config.base_url).to eq('https://custom.url')
      expect(config.timeout).to eq(60)
      expect(config.store_id).to eq(42)
    end
  end

  describe '#validate!' do
    it 'raises when application_id is missing' do
      config = described_class.new(secret: 'secret')
      expect { config.validate! }.to raise_error(ArgumentError, /application_id/)
    end

    it 'raises when secret is missing' do
      config = described_class.new(application_id: 'app')
      expect { config.validate! }.to raise_error(ArgumentError, /secret/)
    end

    it 'raises when application_id is empty string' do
      config = described_class.new(application_id: '', secret: 'secret')
      expect { config.validate! }.to raise_error(ArgumentError, /application_id/)
    end

    it 'passes when both are present' do
      config = described_class.new(application_id: 'app', secret: 'secret')
      expect { config.validate! }.not_to raise_error
    end
  end

  describe '#merge' do
    it 'creates new config with overrides' do
      original = described_class.new(application_id: 'app', secret: 'secret', store_id: 1)
      merged = original.merge(store_id: 2)

      expect(merged.application_id).to eq('app')
      expect(merged.store_id).to eq(2)
      expect(original.store_id).to eq(1) # original unchanged
    end
  end
end
