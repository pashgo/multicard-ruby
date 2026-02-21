# frozen_string_literal: true

module Multicard
  module Resources
    class Payouts < Base
      # Create a payout to a card.
      #
      # @param card_number [String] recipient card number
      # @param amount [Integer] amount in tiyin
      # @param options [Hash] additional params
      # @return [Response]
      def create(card_number:, amount:, **options)
        post('/payout', {
               card_number: card_number,
               amount: amount,
               **options
             })
      end

      # Confirm a payout.
      #
      # @param payout_id [String] payout ID
      # @return [Response]
      def confirm(payout_id)
        post("/payout/#{encode_path(payout_id)}/confirm")
      end

      # Retrieve payout info.
      #
      # @param payout_id [String] payout ID
      # @return [Response]
      def retrieve(payout_id)
        get("/payout/#{encode_path(payout_id)}")
      end
    end
  end
end
