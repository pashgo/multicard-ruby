# frozen_string_literal: true

RSpec.describe Multicard::HttpClient do
  let(:config) do
    Multicard::Configuration.new(
      application_id: 'app',
      secret: 'secret',
      timeout: 30,
      open_timeout: 10
    )
  end
  let(:http_client) { described_class.new(config) }
  let(:base_url) { Multicard::TestHelpers::BASE_URL }

  describe '#get' do
    it 'makes a GET request and returns Response' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 200, body: { success: true, data: { id: 1 } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      response = http_client.get('/test')
      expect(response).to be_a(Multicard::Response)
      expect(response.data[:id]).to eq(1)
    end

    it 'passes query params' do
      stub_request(:get, "#{base_url}/test?page=2")
        .to_return(status: 200, body: { success: true, data: {} }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      http_client.get('/test', params: { page: 2 })
      expect(WebMock).to have_requested(:get, "#{base_url}/test").with(query: { page: 2 })
    end
  end

  describe '#post' do
    it 'sends JSON body' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 200, body: { success: true, data: {} }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      http_client.post('/test', body: { amount: 100 })
      expect(WebMock).to have_requested(:post, "#{base_url}/test")
        .with(body: { amount: 100 })
    end
  end

  describe '#delete' do
    it 'makes a DELETE request' do
      stub_request(:delete, "#{base_url}/test/123")
        .to_return(status: 200, body: { success: true, data: {} }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      response = http_client.delete('/test/123')
      expect(response.success?).to be true
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 401, body: { success: false, error: { code: 'UNAUTHORIZED' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { http_client.get('/test') }.to raise_error(Multicard::AuthenticationError)
    end

    it 'raises ValidationError on 400' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 400, body: { success: false, error: { code: 'ERROR_FIELDS', details: 'Bad input' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { http_client.post('/test') }.to raise_error(Multicard::InvalidFieldsError) do |e|
        expect(e.http_status).to eq(400)
        expect(e.error_code).to eq('ERROR_FIELDS')
        expect(e.error_details).to eq('Bad input')
      end
    end

    it 'raises NotFoundError on 404' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 404, body: { success: false, error: { code: 'NOT_FOUND' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { http_client.get('/test') }.to raise_error(Multicard::NotFoundError)
    end

    it 'raises ServerError on 500' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 500, body: { success: false, error: { code: 'INTERNAL' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { http_client.get('/test') }.to raise_error(Multicard::ServerError)
    end

    it 'raises InsufficientFundsError for ERROR_INSUFFICIENT_FUNDS' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 400,
                   body: { success: false, error: { code: 'ERROR_INSUFFICIENT_FUNDS', details: 'No funds' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { http_client.post('/test') }.to raise_error(Multicard::InsufficientFundsError)
    end

    it 'raises DebitUnknownError for ERROR_DEBIT_UNKNOWN' do
      stub_request(:post, "#{base_url}/test")
        .to_return(status: 400,
                   body: { success: false, error: { code: 'ERROR_DEBIT_UNKNOWN' } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { http_client.post('/test') }.to raise_error(Multicard::DebitUnknownError)
    end

    it 'raises NetworkError on timeout' do
      stub_request(:get, "#{base_url}/test").to_timeout

      expect { http_client.get('/test') }.to raise_error(Multicard::NetworkError, /timed out/)
    end
  end

  describe '#get_with_retry' do
    it 'retries on NetworkError' do
      stub = stub_request(:get, "#{base_url}/test")
             .to_timeout
             .then.to_return(status: 200, body: { success: true, data: {} }.to_json,
                             headers: { 'Content-Type' => 'application/json' })

      response = http_client.get_with_retry('/test', retries: 1)
      expect(response.success?).to be true
      expect(stub).to have_been_requested.twice
    end

    it 'raises after exhausting retries' do
      stub_request(:get, "#{base_url}/test").to_timeout

      expect { http_client.get_with_retry('/test', retries: 1) }
        .to raise_error(Multicard::NetworkError)
    end
  end

  describe 'logging' do
    let(:logger) { instance_double(Logger, info: nil) }
    let(:config_with_logger) do
      Multicard::Configuration.new(
        application_id: 'app', secret: 'secret', logger: logger
      )
    end
    let(:client_with_logger) { described_class.new(config_with_logger) }

    it 'logs request and response' do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 200, body: { success: true, data: {} }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      client_with_logger.get('/test')

      expect(logger).to have_received(:info).with(%r{GET.*/test}).once
      expect(logger).to have_received(:info).with(/200/).once
    end
  end
end
