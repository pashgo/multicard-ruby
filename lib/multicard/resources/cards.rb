# frozen_string_literal: true

module Multicard
  module Resources
    class Cards < Base
      # --- Form-based card binding ---

      # Create a card binding session (returns a link for the user).
      #
      # @param options [Hash] optional params
      # @return [Response] with binding URL and session_id
      def create_binding_link(**options)
        post('/card/bind/session', options)
      end

      # Check binding session status.
      #
      # @param session_id [String] binding session ID
      # @return [Response]
      def binding_status(session_id)
        get("/card/bind/status/#{encode_path(session_id)}")
      end

      # --- API-based card binding (PCI DSS required) ---

      # Send SMS OTP for card binding.
      #
      # @param card_number [String] card number
      # @param card_expiry [String] card expiry (MMYY)
      # @return [Response]
      def add(card_number:, card_expiry:)
        post('/card/add', { number: card_number, expiry: card_expiry })
      end

      # Confirm card binding with SMS code.
      #
      # @param otp_code [String] SMS OTP code
      # @param params [Hash] additional params
      # @return [Response]
      def confirm_binding(otp_code:, **params)
        post('/card/bind/confirm', { code: otp_code, **params })
      end

      # --- Common operations ---

      # Get card info by token.
      #
      # @param token [String] card token
      # @return [Response]
      def retrieve(token)
        get("/card/#{encode_path(token)}")
      end

      # Check a card number (validate).
      #
      # @param card_number [String] card number
      # @return [Response]
      def check(card_number)
        get("/card/check/#{encode_path(card_number)}")
      end

      # Verify card ownership via PINFL (personal ID).
      #
      # @param token [String] card token
      # @param pinfl [String] personal identification number
      # @return [Response]
      def verify_pinfl(token:, pinfl:)
        post('/card/verify/pinfl', { token: token, pinfl: pinfl })
      end

      # Revoke (unbind) a card token.
      #
      # @param token [String] card token
      # @return [Response]
      def revoke(token)
        delete("/card/#{encode_path(token)}")
      end
    end
  end
end
