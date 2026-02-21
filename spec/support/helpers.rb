# frozen_string_literal: true

module Multicard
  module TestHelpers
    BASE_URL = 'https://api.multicard.uz'

    def build_client(**overrides)
      Multicard::Client.new(
        application_id: 'test_app_id',
        secret: 'test_secret',
        store_id: 100,
        **overrides
      )
    end

    def stub_token_request(token: 'test_token_abc')
      stub_request(:post, "#{BASE_URL}/auth")
        .to_return(
          status: 200,
          body: fixture('token', token: token),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def stub_api(method, path, status: 200, body: {}, response_body: nil)
      stub_request(method, "#{BASE_URL}#{path}")
        .to_return(
          status: status,
          body: (response_body || success_response(body)).to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def success_response(data = {})
      { success: true, data: data }
    end

    def error_response(code: 'ERROR_FIELDS', details: 'Invalid request')
      { success: false, error: { code: code, details: details } }
    end

    def fixture(name, **vars)
      path = File.join(__dir__, '..', 'fixtures', 'responses', "#{name}.json")
      content = File.read(path)
      vars.each { |key, value| content.gsub!("{{#{key}}}", value.to_s) }
      content
    end

    def fixture_json(name, **vars)
      JSON.parse(fixture(name, **vars), symbolize_names: true)
    end
  end
end

RSpec.configure do |config|
  config.include Multicard::TestHelpers
end
