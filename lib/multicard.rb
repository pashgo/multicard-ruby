# frozen_string_literal: true

require_relative 'multicard/version'
require_relative 'multicard/configuration'
require_relative 'multicard/errors'
require_relative 'multicard/response'
require_relative 'multicard/http_client'
require_relative 'multicard/token_manager'
require_relative 'multicard/signature'
require_relative 'multicard/client'
require_relative 'multicard/resources/base'
require_relative 'multicard/resources/invoices'
require_relative 'multicard/resources/payments'
require_relative 'multicard/resources/cards'
require_relative 'multicard/resources/holds'
require_relative 'multicard/resources/payouts'
require_relative 'multicard/resources/registry'

module Multicard
  class << self
    attr_reader :configuration

    # Configure the gem globally (optional — you can also pass config per-client).
    #
    #   Multicard.configure do |config|
    #     config.application_id = ENV["MULTICARD_APPLICATION_ID"]
    #     config.secret = ENV["MULTICARD_SECRET"]
    #     config.store_id = 123
    #   end
    #
    def configure
      @configuration = Configuration.new
      yield(@configuration) if block_given?
      @configuration
    end

    # Reset global configuration (useful in tests).
    def reset_configuration!
      @configuration = nil
    end
  end
end
