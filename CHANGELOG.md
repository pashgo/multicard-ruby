# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-02-21

### Changed

- Updated gem author metadata
- Replaced HTTP.rb with Net::HTTP (zero runtime dependencies)

## [0.1.0] - 2026-02-21

### Added

- Initial release
- Configuration (global and per-client with immutable merge)
- HTTP client (HTTP.rb) with retry logic and exponential backoff
- Thread-safe token management with Mutex (23h TTL, auto-refresh)
- Automatic retry on 401 (token expiry)
- Resources: Invoices, Payments, Cards, Holds, Payouts, Registry (33 methods, 100% API coverage)
- Split payments support (multi-recipient)
- Wallet payments (Payme, Click, Uzum, Anorbank, Xazna, etc.)
- Webhook signature verification (MD5, constant-time comparison, amount normalization)
- Full error hierarchy with Multicard-specific error codes (ERROR_MAP)
- Comprehensive test suite (90 specs, WebMock)
