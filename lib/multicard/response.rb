# frozen_string_literal: true

module Multicard
  class Response
    attr_reader :http_status, :body, :headers

    def initialize(http_status:, body:, headers: {})
      @http_status = http_status
      @body = body
      @headers = headers
    end

    def success?
      body[:success] == true
    end

    def data
      body[:data]
    end

    def error_code
      body.dig(:error, :code)
    end

    def error_details
      body.dig(:error, :details)
    end

    def [](key)
      data&.[](key)
    end
  end
end
