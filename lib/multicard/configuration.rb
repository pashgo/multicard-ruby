# frozen_string_literal: true

module Multicard
  class Configuration
    attr_accessor :application_id, :secret, :base_url, :timeout, :open_timeout, :logger, :store_id

    DEFAULT_BASE_URL = 'https://api.multicard.uz'
    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 10

    def initialize(**options)
      @application_id = options[:application_id]
      @secret = options[:secret]
      @base_url = options[:base_url] || DEFAULT_BASE_URL
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
      @open_timeout = options[:open_timeout] || DEFAULT_OPEN_TIMEOUT
      @logger = options[:logger]
      @store_id = options[:store_id]
    end

    def validate!
      raise ArgumentError, 'application_id is required' if application_id.nil? || application_id.to_s.empty?
      raise ArgumentError, 'secret is required' if secret.nil? || secret.to_s.empty?
    end

    # Merge per-client overrides into this configuration.
    # Uses .key? for fields where nil/0/false are valid override values
    # (e.g., store_id: nil to clear, timeout: 0 to disable).
    def merge(overrides)
      self.class.new(
        application_id: overrides[:application_id] || application_id,
        secret: overrides[:secret] || secret,
        base_url: overrides[:base_url] || base_url,
        timeout: overrides.key?(:timeout) ? overrides[:timeout] : timeout,
        open_timeout: overrides.key?(:open_timeout) ? overrides[:open_timeout] : open_timeout,
        logger: overrides.key?(:logger) ? overrides[:logger] : logger,
        store_id: overrides.key?(:store_id) ? overrides[:store_id] : store_id
      )
    end
  end
end
