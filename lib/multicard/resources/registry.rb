# frozen_string_literal: true

module Multicard
  module Resources
    class Registry < Base
      # Get payment registry (list of processed payments).
      #
      # @param filters [Hash] filter params (date_from, date_to, status, etc.)
      # @return [Response]
      def payments(**filters)
        get('/payments/registry', filters)
      end

      # Get payout history.
      #
      # @param filters [Hash] filter params
      # @return [Response]
      def payouts(**filters)
        get('/payout/history', filters)
      end

      # Get application info.
      #
      # @return [Response]
      def application_info
        get('/app/info')
      end

      # Get merchant banking details.
      #
      # @return [Response]
      def merchant_details
        get('/merchant/details')
      end
    end
  end
end
