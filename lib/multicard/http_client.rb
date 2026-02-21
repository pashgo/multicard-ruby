# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Multicard
  class HttpClient
    def initialize(config)
      @config = config
    end

    def get(path, params: {}, headers: {})
      request(:get, path, params: params, headers: headers)
    end

    def post(path, body: {}, headers: {})
      request(:post, path, body: body, headers: headers)
    end

    def delete(path, params: {}, headers: {})
      request(:delete, path, params: params, headers: headers)
    end

    def get_with_retry(path, params: {}, headers: {}, retries: 2)
      request_with_retry(:get, path, params: params, headers: headers, retries: retries)
    end

    private

    def request(method, path, body: nil, params: nil, headers: {})
      uri = build_uri(path, params)
      log_request(method, uri.to_s)

      req = build_request(method, uri, body, headers)
      raw = execute(uri, req)

      log_response(raw)
      handle_response(raw)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise NetworkError, "Request timed out: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
      raise NetworkError, "Connection failed: #{e.message}"
    end

    def request_with_retry(method, path, retries: 2, **options)
      attempts = 0
      begin
        request(method, path, **options)
      rescue NetworkError, RateLimitError, ServerError
        attempts += 1
        raise if attempts > retries

        sleep((2**attempts) * 0.5)
        retry
      end
    end

    def build_uri(path, params)
      uri = URI("#{@config.base_url}#{path}")
      uri.query = URI.encode_www_form(params) if params && !params.empty?
      uri
    end

    def build_request(method, uri, body, headers)
      req_class = case method
                  when :get then Net::HTTP::Get
                  when :post then Net::HTTP::Post
                  when :delete then Net::HTTP::Delete
                  else raise ArgumentError, "Unsupported HTTP method: #{method}"
                  end

      req = req_class.new(uri)
      req['Accept'] = 'application/json'
      req['Content-Type'] = 'application/json'
      headers.each { |key, value| req[key] = value }
      req.body = body.to_json if body
      req
    end

    def execute(uri, req)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = @config.open_timeout
      http.read_timeout = @config.timeout
      http.request(req)
    end

    def handle_response(raw)
      status = raw.code.to_i
      body = parse_body(raw)
      raise_api_error(status, body) unless status.between?(200, 299)

      Response.new(http_status: status, body: body, headers: response_headers(raw))
    end

    def parse_body(raw)
      JSON.parse(raw.body || '', symbolize_names: true)
    rescue JSON::ParserError
      { raw: raw.body }
    end

    def response_headers(raw)
      headers = {}
      raw.each_header { |key, value| headers[key] = value }
      headers
    end

    def raise_api_error(status, body)
      error_code = body.dig(:error, :code)
      error_details = body.dig(:error, :details)
      error_class = ERROR_MAP[error_code] || error_class_for_status(status)

      raise error_class.new(
        error_details,
        http_status: status,
        error_code: error_code,
        error_details: error_details,
        response_body: body
      )
    end

    def error_class_for_status(status)
      case status
      when 401 then AuthenticationError
      when 404 then NotFoundError
      when 429 then RateLimitError
      when 400..499 then ValidationError
      when 500..599 then ServerError
      else Error
      end
    end

    def log_request(method, url)
      return unless @config.logger

      @config.logger.info("[Multicard] #{method.to_s.upcase} #{url}")
    end

    def log_response(raw)
      return unless @config.logger

      @config.logger.info("[Multicard] #{raw.code}")
    end
  end
end
