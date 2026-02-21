# frozen_string_literal: true

module Multicard
  module Resources
    class Invoices < Base
      # Create an invoice (hosted checkout page).
      #
      # @param amount [Integer] amount in tiyin
      # @param invoice_id [String] your order ID
      # @param callback_url [String] webhook URL
      # @param store_id [Integer, nil] register ID (falls back to config.store_id)
      # @param options [Hash] additional params (description, lifetime, return_url, etc.)
      # @return [Response]
      def create(amount:, invoice_id:, callback_url:, store_id: nil, **options)
        post('/payment/invoice', {
          amount: amount,
          store_id: store_id || default_store_id,
          invoice_id: invoice_id,
          callback_url: callback_url,
          **options
        }.compact)
      end

      # Retrieve invoice info.
      #
      # @param invoice_id [String] invoice ID
      # @return [Response]
      def retrieve(invoice_id)
        get("/invoice/#{encode_path(invoice_id)}")
      end

      # Cancel an unpaid invoice.
      #
      # @param invoice_id [String] invoice ID
      # @return [Response]
      def cancel(invoice_id)
        delete("/invoice/#{encode_path(invoice_id)}")
      end

      # Generate a Quick Pay link (Payme, Click, Uzum QR, etc.).
      #
      # @param invoice_id [String] invoice ID
      # @param service [String] payment service name
      # @return [Response]
      def quick_pay(invoice_id:, service:)
        post('/invoice/quick-pay', {
               invoice_id: invoice_id,
               service: service
             })
      end
    end
  end
end
