# frozen_string_literal: true

require_relative 'lib/multicard/version'

Gem::Specification.new do |spec|
  spec.name = 'multicard'
  spec.version = Multicard::VERSION
  spec.authors = [ 'Pavel Skripin' ]
  spec.email = [ 'skripin.pavel@gmail.com' ]

  spec.summary = 'Ruby client for the Multicard payment gateway (Uzbekistan)'
  spec.description = 'Ruby SDK for Multicard.uz — payment gateway supporting Uzcard, Humo, ' \
                     'and 9 wallet apps (Payme, Click, Uzum, etc.). Invoices, card payments, ' \
                     'splits, holds, payouts, card binding, and webhook verification.'
  spec.homepage = 'https://github.com/pashgo/multicard-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = [ 'lib' ]

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
