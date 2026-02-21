# frozen_string_literal: true

module Multicard
  class Error < StandardError
    attr_reader :http_status, :error_code, :error_details, :response_body

    def initialize(message = nil, http_status: nil, error_code: nil, error_details: nil, response_body: nil)
      @http_status = http_status
      @error_code = error_code
      @error_details = error_details
      @response_body = response_body
      super(message || error_details || 'Multicard API error')
    end
  end

  # HTTP errors
  class AuthenticationError < Error; end
  class ValidationError < Error; end
  class NotFoundError < Error; end
  class RateLimitError < Error; end
  class ServerError < Error; end
  class NetworkError < Error; end

  # Business errors (from error.code in API response)
  class CardNotFoundError < ValidationError; end
  class InsufficientFundsError < ValidationError; end
  class CardExpiredError < ValidationError; end
  class DebitUnknownError < Error; end
  class CallbackTimeoutError < Error; end
  class InvalidFieldsError < ValidationError; end

  # Maps Multicard error codes to Ruby exception classes
  ERROR_MAP = {
    'ERROR_CARD_NOT_FOUND' => CardNotFoundError,
    'ERROR_INSUFFICIENT_FUNDS' => InsufficientFundsError,
    'ERROR_CARD_EXPIRED' => CardExpiredError,
    'ERROR_DEBIT_UNKNOWN' => DebitUnknownError,
    'ERROR_CALLBACK_TIMEOUT' => CallbackTimeoutError,
    'ERROR_FIELDS' => InvalidFieldsError
  }.freeze
end
