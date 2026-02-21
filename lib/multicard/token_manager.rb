# frozen_string_literal: true

module Multicard
  class TokenManager
    TOKEN_TTL = 23 * 3600 # Refresh 1 hour before 24h expiry

    def initialize(http_client, config)
      @http_client = http_client
      @config = config
      @token = nil
      @expires_at = nil
      @mutex = Mutex.new
    end

    def token
      @mutex.synchronize do
        refresh! if expired?
        @token
      end
    end

    def reset!
      @mutex.synchronize do
        @token = nil
        @expires_at = nil
      end
    end

    private

    def refresh!
      response = @http_client.post(
        '/auth',
        body: {
          application_id: @config.application_id,
          secret: @config.secret
        }
      )
      # Auth endpoint returns {"token": "..."} directly, not wrapped in {"success": true, "data": {...}}
      @token = response.body[:token]
      raise AuthenticationError, 'Auth response missing token' unless @token

      @expires_at = Time.now + TOKEN_TTL
    end

    def expired?
      @token.nil? || @expires_at.nil? || Time.now >= @expires_at
    end
  end
end
