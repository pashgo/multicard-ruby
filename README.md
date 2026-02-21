# Multicard Ruby SDK

[![Gem Version](https://badge.fury.io/rb/multicard.svg)](https://badge.fury.io/rb/multicard)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Ruby client for the [Multicard](https://multicard.uz) payment gateway (Uzbekistan).

Supports Uzcard, Humo, and wallet apps: Payme, Click, Uzum, Anorbank, Xazna, and more.

## Why This Gem?

Before this SDK, integrating with Multicard meant writing raw HTTP calls, managing tokens manually, and handling errors ad-hoc. Here's what the gem gives you:

### Full API Coverage

30 methods across 6 resource groups — invoices, payments (token/card/wallet/split), card binding, holds (pre-auth), payouts, and registry. No need to study the API docs for every endpoint.

### Clean Resource-Based Interface

Stripe/Shopify-style SDK design:

```ruby
client.payments.create_by_token(card_token: 'tok_abc', amount: 500_000, invoice_id: 'ORD-1')
client.holds.capture(hold_id, amount: 300_000)
client.cards.create_binding_link
```

Discoverable, self-documenting API — IDE autocompletion works out of the box.

### Automatic Token Management

Bearer tokens (24h TTL) are fetched, cached, and refreshed transparently. Thread-safe with Mutex. On 401, the gem automatically refreshes the token and retries the request — zero manual intervention.

### Typed Error Hierarchy

Multicard error codes map to specific Ruby exceptions:

```ruby
rescue Multicard::InsufficientFundsError  # not enough funds
rescue Multicard::CardExpiredError         # card expired
rescue Multicard::DebitUnknownError        # need to poll for status
rescue Multicard::NetworkError             # timeout / connection lost
```

Each exception carries `http_status`, `error_code`, `error_details`, and `response_body` — no parsing required.

### Framework-Agnostic

Zero runtime dependencies. Uses Ruby's built-in `Net::HTTP` — no external gems required. Works in any Ruby app — Rails, Sinatra, Hanami, plain scripts.

### Built-In Security

- Webhook signature verification with constant-time comparison (timing-attack safe)
- No sensitive data in logs (token values are never logged)
- Automatic retry with exponential backoff for transient failures

### Production-Ready

- 91 specs with WebMock (no real HTTP calls in tests)
- Thread-safe token caching
- Configurable timeouts (connect + read)
- Optional logger support for debugging
- Global config + per-client overrides for multi-tenant setups

## Installation

Add to your Gemfile:

```ruby
gem 'multicard'
```

Or install directly:

```
gem install multicard
```

## Quick Start

```ruby
require 'multicard'

client = Multicard::Client.new(
  application_id: ENV['MULTICARD_APPLICATION_ID'],
  secret: ENV['MULTICARD_SECRET'],
  store_id: 123  # default register ID
)

# Create a hosted checkout invoice
invoice = client.invoices.create(
  amount: 500_000,          # 5,000 UZS in tiyin
  invoice_id: 'ORD-001',
  callback_url: 'https://example.com/webhooks/multicard'
)

# Redirect user to payment page
invoice.data[:checkout_url]
```

## Configuration

### Global (optional)

```ruby
Multicard.configure do |config|
  config.application_id = ENV['MULTICARD_APPLICATION_ID']
  config.secret = ENV['MULTICARD_SECRET']
  config.base_url = 'https://api.multicard.uz'  # default
  config.timeout = 30                            # default (seconds)
  config.open_timeout = 10                       # default (seconds)
  config.logger = Logger.new($stdout)            # optional
  config.store_id = 123                          # default store/register ID
end

# Then create clients without repeating credentials:
client = Multicard::Client.new
```

### Per-client (overrides global)

```ruby
client = Multicard::Client.new(
  application_id: 'other_app_id',
  secret: 'other_secret',
  store_id: 456
)
```

## Invoices (Hosted Checkout)

```ruby
# Create invoice
invoice = client.invoices.create(
  amount: 500_000,
  invoice_id: 'ORD-001',
  callback_url: 'https://example.com/cb',
  return_url: 'https://example.com/success',
  description: 'Order payment'
)
invoice.data[:checkout_url]  # redirect user here

# Get invoice info
info = client.invoices.retrieve('ORD-001')

# Cancel unpaid invoice
client.invoices.cancel('ORD-001')

# Quick Pay (Payme, Click, Uzum QR)
client.invoices.quick_pay(invoice_id: 'ORD-001', service: 'payme')
```

## Payments

### By Card Token

```ruby
payment = client.payments.create_by_token(
  card_token: 'tok_abc',
  amount: 500_000,
  invoice_id: 'ORD-001',
  callback_url: 'https://example.com/cb'
)
```

### By Card Number (PCI DSS required)

```ruby
payment = client.payments.create_by_card(
  card_number: '8600123456781234',
  card_expiry: '1228',
  amount: 500_000,
  invoice_id: 'ORD-002'
)
```

### Wallet Payment

```ruby
payment = client.payments.create_wallet(
  service: 'payme',  # or 'click', 'uzum', etc.
  amount: 300_000,
  invoice_id: 'ORD-003'
)
```

### Split Payment

```ruby
payment = client.payments.create_split(
  card_token: 'tok_abc',
  amount: 500_000,
  invoice_id: 'ORD-004',
  split: [
    { type: 'account', amount: 400_000, details: 'Store share', recipient: 'uuid-1' },
    { type: 'wallet', amount: 100_000, details: 'Platform fee' }
  ]
)
```

### OTP Confirmation

```ruby
client.payments.confirm('payment-uuid', otp_code: '123456')
```

### Refunds

```ruby
# Full refund
client.payments.refund('payment-uuid')

# Partial refund
client.payments.partial_refund('payment-uuid', amount: 100_000)
```

### Fiscal Receipt

```ruby
client.payments.send_fiscal_link('payment-uuid', fiscal_url: 'https://ofd.uz/receipt/123')
```

### With OFD Data

```ruby
client.payments.create_by_token(
  card_token: 'tok_abc',
  amount: 500_000,
  invoice_id: 'ORD-005',
  ofd: [
    { name: 'Product', price: 500_000, qty: 1, vat: 12,
      tin: '123456789', mxik: '10202001001000000', package_code: '1508574' }
  ]
)
```

## Card Binding

### Form-Based (recommended)

```ruby
# Get binding link
link = client.cards.create_binding_link
# Redirect user to: link.data[:url]

# Check status (polling)
status = client.cards.binding_status(link.data[:session_id])
status.data[:token]  # card token when bound
```

### API-Based (PCI DSS required)

```ruby
# Send OTP
client.cards.add(card_number: '8600123456781234', card_expiry: '1228')

# Confirm with OTP
result = client.cards.confirm_binding(otp_code: '123456')
result.data[:token]
```

### Card Operations

```ruby
# Get card info
card = client.cards.retrieve('card_token')

# Check card number
client.cards.check('8600123456781234')

# Verify ownership (PINFL)
client.cards.verify_pinfl(token: 'card_token', pinfl: '12345678901234')

# Unbind card
client.cards.revoke('card_token')
```

## Holds (Pre-Authorization)

```ruby
# Create hold
hold = client.holds.create(
  card_token: 'tok_abc',
  amount: 500_000,
  invoice_id: 'HOLD-001'
)

# Confirm hold (block funds)
client.holds.confirm(hold.data[:id], otp_code: '123456')

# Capture full amount
client.holds.capture(hold.data[:id])

# Capture partial amount
client.holds.capture(hold.data[:id], amount: 300_000)

# Cancel hold (release funds)
client.holds.cancel(hold.data[:id])

# Check hold status
client.holds.retrieve(hold.data[:id])
```

## Payouts

```ruby
# Create payout
payout = client.payouts.create(card_number: '8600999988887777', amount: 100_000)

# Confirm payout
client.payouts.confirm(payout.data[:id])

# Check status
client.payouts.retrieve(payout.data[:id])
```

## Registry

```ruby
# Payment registry
client.registry.payments(date_from: '2025-01-01', date_to: '2025-01-31')

# Payout history
client.registry.payouts

# Application info
client.registry.application_info

# Merchant banking details
client.registry.merchant_details
```

## Webhook Verification

Multicard signs callback requests with MD5: `sign = md5(store_id + invoice_id + amount + secret)`.

`Signature.verify` handles this for you, including:
- **Constant-time comparison** — prevents timing attacks (no `Rack` dependency needed)
- **Amount normalization** — Multicard callbacks inconsistently format amounts (`"50000"`, `"50000.0"`, or `"50000.00"`). The signature is always computed against the integer form, so trailing `.0`/`.00` are stripped automatically.
- **Case-insensitive** — uppercase/lowercase hex signatures both accepted

```ruby
# In your webhook controller:
def multicard_callback
  params = request.params.symbolize_keys

  unless Multicard::Signature.verify(params, secret: ENV['MULTICARD_SECRET'])
    head :unauthorized
    return
  end

  payment = client.payments.retrieve(params[:uuid])
  # Process payment...
  head :ok
end
```

## Error Handling

```ruby
begin
  client.payments.create_by_token(
    card_token: 'tok_abc',
    amount: 500_000,
    invoice_id: 'ORD-001'
  )
rescue Multicard::CardNotFoundError => e
  # Card token is invalid or revoked
rescue Multicard::InsufficientFundsError => e
  # Not enough funds on the card
rescue Multicard::CardExpiredError => e
  # Card has expired
rescue Multicard::DebitUnknownError => e
  # Unknown debit status - poll for result
  payment = client.payments.retrieve(e.response_body.dig(:data, :uuid))
rescue Multicard::InvalidFieldsError => e
  # Validation error - check e.error_details
rescue Multicard::AuthenticationError => e
  # Invalid credentials
rescue Multicard::NetworkError => e
  # Timeout or connection failure
rescue Multicard::ServerError => e
  # Multicard server error (5xx)
rescue Multicard::Error => e
  # Any other Multicard error
  e.http_status     # HTTP status code
  e.error_code      # Multicard error code string
  e.error_details   # Human-readable error description
  e.response_body   # Full response body hash
end
```

## Development

```bash
bundle install
bundle exec rspec          # run tests
bundle exec rubocop        # lint
gem build multicard.gemspec  # build gem
```

## License

MIT License. See [LICENSE](LICENSE).
