# Contributing to Multicard Ruby SDK

Bug reports and pull requests are welcome on [GitHub](https://github.com/pashgo/multicard-ruby).

## Getting Started

```bash
git clone https://github.com/pashgo/multicard-ruby.git
cd multicard-ruby
bundle install
```

## Development

```bash
bundle exec rspec          # run tests
bundle exec rubocop        # lint
gem build multicard.gemspec  # build gem
```

## Pull Requests

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Write tests for your changes
4. Make sure all tests pass (`bundle exec rspec`)
5. Make sure rubocop is clean (`bundle exec rubocop`)
6. Commit using [conventional commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `refactor:`)
7. Open a Pull Request

## Code Style

- Follow existing patterns in the codebase
- Add YARD-style `@param` / `@return` docs for public methods
- Keep resource methods thin — business logic stays in `HttpClient` and `Client`

## Adding a New Resource

1. Create `lib/multicard/resources/my_resource.rb` inheriting from `Resources::Base`
2. Add `require_relative` in `lib/multicard.rb`
3. Add lazy accessor in `Client`: `def my_resource = @my_resource ||= Resources::MyResource.new(self)`
4. Create `spec/multicard/resources/my_resource_spec.rb`
5. Add JSON fixtures in `spec/fixtures/responses/` if needed
6. Document usage in `README.md`

## Reporting Bugs

Open an issue with:
- Ruby version (`ruby -v`)
- Gem version (`Multicard::VERSION`)
- Minimal reproduction code
- Expected vs actual behavior
