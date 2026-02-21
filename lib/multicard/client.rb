# frozen_string_literal: true

module Multicard
  class Client
    attr_reader :config

    def initialize(**options)
      @config = if Multicard.configuration
        Multicard.configuration.merge(options)
      else
        Configuration.new(**options)
      end
      @config.validate!
      @http_client = HttpClient.new(@config)
      @token_manager = TokenManager.new(@http_client, @config)
    end

    # Resource accessors (lazy-initialized)
    def invoices  = @invoices ||= Resources::Invoices.new(self)
    def payments  = @payments ||= Resources::Payments.new(self)
    def cards     = @cards ||= Resources::Cards.new(self)
    def holds     = @holds ||= Resources::Holds.new(self)
    def payouts   = @payouts ||= Resources::Payouts.new(self)
    def registry  = @registry ||= Resources::Registry.new(self)

    # Execute an authenticated API request. Automatically retries once on 401.
    #
    # @param method [Symbol] :get, :post, or :delete
    # @param path [String] API path
    # @param body [Hash, nil] request body (for POST)
    # @param params [Hash, nil] query params (for GET/DELETE)
    # @return [Response]
    def authenticated_request(method, path, body: nil, params: nil)
      execute_authenticated(method, path, body: body, params: params)
    rescue AuthenticationError
      @token_manager.reset!
      execute_authenticated(method, path, body: body, params: params)
    end

    private

    def execute_authenticated(method, path, body: nil, params: nil)
      headers = { 'Authorization' => "Bearer #{@token_manager.token}" }

      case method
      when :get
        # GET is idempotent — safe to retry on transient failures (timeout, 429, 5xx)
        @http_client.get_with_retry(path, params: params || {}, headers: headers)
      when :post
        # POST is NOT retried by default — retrying a payment could cause double charges.
        # The 401 retry in authenticated_request is still applied (token refresh).
        @http_client.post(path, body: body || {}, headers: headers)
      when :delete
        @http_client.delete(path, params: params || {}, headers: headers)
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end
    end
  end
end
