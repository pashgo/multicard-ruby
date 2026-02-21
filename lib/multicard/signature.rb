# frozen_string_literal: true

require 'digest'

module Multicard
  class Signature
    # Verify a webhook callback signature.
    #
    # @param params [Hash] webhook parameters (:store_id, :invoice_id, :amount, :sign)
    # @param secret [String] application secret
    # @return [Boolean]
    def self.verify(params, secret:)
      store_id = params[:store_id].to_s
      invoice_id = params[:invoice_id].to_s
      amount = normalize_amount(params[:amount].to_s)
      sign = params[:sign].to_s

      return false if sign.empty?

      expected = Digest::MD5.hexdigest("#{store_id}#{invoice_id}#{amount}#{secret}")
      secure_compare(expected.downcase, sign.downcase)
    end

    # Constant-time string comparison to prevent timing attacks.
    #
    # Regular == short-circuits on the first mismatched byte, so an attacker
    # can measure response time and brute-force the signature byte by byte.
    # XOR-ing every pair and OR-accumulating makes execution time depend only
    # on string length, not content.
    #
    # We implement this inline instead of using Rack::Utils.secure_compare
    # to keep the gem dependency-free (no Rack requirement).
    def self.secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      a.bytes.zip(b.bytes).reduce(0) { |acc, (x, y)| acc | (x ^ y) }.zero?
    end

    # Normalize amount: remove trailing ".0" / ".00" / ".000" etc.
    #
    # Multicard callbacks may send amounts as "50000", "50000.0", or "50000.00".
    # The signature is always computed against the integer form (no decimals).
    #
    # Only trailing zeros are stripped (not arbitrary decimals like "50000.10")
    # because Multicard amounts are in tiyin (1/100 of UZS) — always integers.
    # Non-zero decimal digits would indicate a bug in the callback, not valid data.
    def self.normalize_amount(amount)
      amount.sub(/\.0+\z/, '')
    end

    private_class_method :secure_compare, :normalize_amount
  end
end
