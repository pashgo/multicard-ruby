# frozen_string_literal: true

require 'uri'

module Multicard
  module Resources
    class Base
      def initialize(client)
        @client = client
      end

      private

      def get(path, params = {})
        @client.authenticated_request(:get, path, params: params)
      end

      def post(path, body = {})
        @client.authenticated_request(:post, path, body: body)
      end

      def delete(path, params = {})
        @client.authenticated_request(:delete, path, params: params)
      end

      def default_store_id
        @client.config.store_id
      end

      # Encode a path segment to prevent path traversal (../) or special characters.
      def encode_path(value)
        URI.encode_www_form_component(value.to_s)
      end
    end
  end
end
