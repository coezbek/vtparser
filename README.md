# VT 100 Parser Gem

This gem is a parser for VT100 terminal escape sequences. It is based on the C code from https://github.com/haberman/vtparse/.

## Background on VT100 Escape Sequences

See https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add vtparser
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install vtparser
```

## Basic Usage

See the minimal example below and the [`examples`](https://github.com/coezbek/vtparser/examples) directory for more examples.

```ruby
require 'vtparser'

# Instantiate the parser with a block to handle actions
parser = VTParser.new do |action, ch, intermediate_chars, params|

  # For this minimal example, we'll just turn everything back strings to print
  print VtParser::to_ansi(action, ch, intermediate_chars, params)

end

# Sample input containing ANSI escape sequences
input = "\e[31mHello, \e[1mWorld!\e[0m"

# Parse the input
parser.parse(input)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/coezbek/vtparser.
