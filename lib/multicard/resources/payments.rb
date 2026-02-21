# frozen_string_literal: true

module Multicard
  module Resources
    class Payments < Base
      # Pay by saved card token.
      #
      # @param card_token [String] card token from binding
      # @param amount [Integer] amount in tiyin
      # @param invoice_id [String] your order ID
      # @param store_id [Integer, nil] register ID
      # @param callback_url [String, nil] webhook URL
      # @param ofd [Array<Hash>, nil] fiscal receipt items
      # @return [Response]
      def create_by_token(card_token:, amount:, invoice_id:, store_id: nil,
                          callback_url: nil, ofd: nil, **options)
        post('/payment/token', {
          card: { token: card_token },
          amount: amount,
          store_id: store_id || default_store_id,
          invoice_id: invoice_id,
          callback_url: callback_url,
          ofd: ofd,
          **options
        }.compact)
      end

      # Pay by card number (requires PCI DSS).
      #
      # @param card_number [String] card number
      # @param card_expiry [String] card expiry (MMYY or MM/YY)
      # @param amount [Integer] amount in tiyin
      # @param invoice_id [String] your order ID
      # @return [Response]
      def create_by_card(card_number:, card_expiry:, amount:, invoice_id:, store_id: nil,
                         callback_url: nil, ofd: nil, **options)
        post('/payment/card', {
          card: { number: card_number, expiry: card_expiry },
          amount: amount,
          store_id: store_id || default_store_id,
          invoice_id: invoice_id,
          callback_url: callback_url,
          ofd: ofd,
          **options
        }.compact)
      end

      # Split payment across multiple recipients.
      #
      # @param card_token [String] card token
      # @param amount [Integer] total amount in tiyin
      # @param invoice_id [String] your order ID
      # @param split [Array<Hash>] split recipients [{type:, amount:, details:, recipient:}]
      # @return [Response]
      def create_split(card_token:, amount:, invoice_id:, split:, store_id: nil,
                       callback_url: nil, ofd: nil, **options)
        post('/payment/split', {
          card: { token: card_token },
          amount: amount,
          store_id: store_id || default_store_id,
          invoice_id: invoice_id,
          callback_url: callback_url,
          split: split,
          ofd: ofd,
          **options
        }.compact)
      end

      # Pay via wallet app (Payme, Click, Uzum, etc.).
      #
      # @param service [String] wallet service name
      # @param amount [Integer] amount in tiyin
      # @param invoice_id [String] your order ID
      # @return [Response]
      def create_wallet(service:, amount:, invoice_id:, store_id: nil,
                        callback_url: nil, ofd: nil, **options)
        post('/payment/app', {
          service: service,
          amount: amount,
          store_id: store_id || default_store_id,
          invoice_id: invoice_id,
          callback_url: callback_url,
          ofd: ofd,
          **options
        }.compact)
      end

      # Confirm a payment (submit OTP code if required).
      #
      # @param payment_id [String] payment ID
      # @param otp_code [String, nil] SMS confirmation code
      # @return [Response]
      def confirm(payment_id, otp_code: nil)
        body = otp_code ? { code: otp_code } : {}
        post("/payment/#{encode_path(payment_id)}/confirm", body)
      end

      # Retrieve payment info.
      #
      # @param payment_id [String] payment ID (UUID)
      # @return [Response]
      def retrieve(payment_id)
        get("/payment/#{encode_path(payment_id)}")
      end

      # Full refund.
      #
      # @param payment_id [String] payment ID (UUID)
      # @return [Response]
      def refund(payment_id)
        delete("/payment/#{encode_path(payment_id)}")
      end

      # Partial refund.
      #
      # @param payment_id [String] payment ID (UUID)
      # @param amount [Integer] refund amount in tiyin
      # @return [Response]
      def partial_refund(payment_id, amount:)
        post("/payment/#{encode_path(payment_id)}/refund/partial", { amount: amount })
      end

      # Submit a fiscal receipt link.
      #
      # @param payment_id [String] payment ID (UUID)
      # @param fiscal_url [String] URL of the fiscal receipt
      # @return [Response]
      def send_fiscal_link(payment_id, fiscal_url:)
        post("/payment/#{encode_path(payment_id)}/fiscal", { fiscal_url: fiscal_url })
      end
    end
  end
end
