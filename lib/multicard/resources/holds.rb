# frozen_string_literal: true

module Multicard
  module Resources
    class Holds < Base
      # Create a hold (pre-authorization).
      #
      # @param card_token [String] card token
      # @param amount [Integer] amount in tiyin
      # @param invoice_id [String] your order ID
      # @param store_id [Integer, nil] register ID
      # @return [Response]
      def create(card_token:, amount:, invoice_id:, store_id: nil, **options)
        post('/hold', {
          card: { token: card_token },
          amount: amount,
          store_id: store_id || default_store_id,
          invoice_id: invoice_id,
          **options
        }.compact)
      end

      # Confirm a hold (block funds on card).
      #
      # @param hold_id [String] hold ID
      # @param otp_code [String, nil] SMS OTP code if required
      # @return [Response]
      def confirm(hold_id, otp_code: nil)
        body = otp_code ? { code: otp_code } : {}
        post("/hold/#{encode_path(hold_id)}/confirm", body)
      end

      # Capture (debit) held funds. Full or partial.
      #
      # @param hold_id [String] hold ID
      # @param amount [Integer, nil] partial capture amount (nil = full capture)
      # @return [Response]
      def capture(hold_id, amount: nil)
        body = amount ? { amount: amount } : {}
        post("/hold/#{encode_path(hold_id)}/charge", body)
      end

      # Retrieve hold info.
      #
      # @param hold_id [String] hold ID
      # @return [Response]
      def retrieve(hold_id)
        get("/hold/#{encode_path(hold_id)}")
      end

      # Cancel a hold (release blocked funds).
      #
      # @param hold_id [String] hold ID
      # @return [Response]
      def cancel(hold_id)
        delete("/hold/#{encode_path(hold_id)}")
      end
    end
  end
end
