# API Diff

Bring APIs into an easily diff-able format.

## Installation

Add this line to your application's `Gemfile`

```ruby
gem 'api_diff'
```

and then execute

```bash
bundle install
```

Or install it yourself as:

```bash
gem install api_diff
```

## Usage

```bash
./api_diff --format FORMAT <input-file>
```

All output is printed to `STDOUT`.

- `--format`: required - specifies the format of the input file (see below).
- `--short-names`: optional - shorten type references by removing package qualifiers.
- `--normalize`: optional - transform API to a common, cross-language baseline. Less accurate when comparing APIs of the same language but helpful when comparing across languages. (Early WIP)

### Supported Formats

- `swift-interface`: Swift module interface files like they are created for frameworks (with library evolution support turned on..?).
- `kotlin-bcv`: The output of [Binary Compatibility Validator](https://github.com/Kotlin/binary-compatibility-validator).

### Limitations

- `kotlin-bcv` currently does not support nullability.

## Development

After checking out the repo, run `bin/setup` to install dependencies. 
Then, run `rake test` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sebastianludwig/api-diff.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
