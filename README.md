# VT 100 Parser Gem

This gem is a parser for VT100 terminal escape sequences. It is based on the C code from https://github.com/haberman/vtparse/ and implements the statemachine from https://www.vt100.net/emu/dec_ansi_parser.

The purpose of this Gem is to have a relatively easy way to filter/modify the output of child/sub-processes (for instance launched via `PTY::spawn`) which use animation or colors. 

Uses keyboard mapping logic from https://github.com/vidarh/keyboard_map/

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

See the minimal example below:

```ruby
require_relative '../lib/vtparser'

# Instantiate the parser with a block to handle actions
parser = VTParser.new do |action|

  # For this minimal example, we'll just turn everything back strings to print
  print action.to_ansi

end

# Sample input containing ANSI escape sequences (red text, bold text)
input = "\e[31mHello, \e[1mWorld!\e[0m\n"

# Parse the input
parser.parse(input)
```

Further samples in the [`examples directory`](https://github.com/coezbek/vtparser/tree/main/examples):

- [`echo_keys.rb`](https://github.com/coezbek/vtparser/tree/main/examples/echo_keys.rb): Echoes the keys pressed by the user
- [`indent_cli.rb`](https://github.com/coezbek/vtparser/tree/main/examples/indent_cli.rb): Indents the output of simple command line tools
- [`colorswap.rb`](https://github.com/coezbek/vtparser/tree/main/examples/colorswap.rb): Swaps the colors red / green in the input program
- [`analyze.rb`](https://github.com/coezbek/vtparser/tree/main/examples/analyze.rb): Output all VT100 escape sequences written by the subprocess.
- [`roundtrip.rb`](https://github.com/coezbek/vtparser/tree/main/examples/roundtrip.rb): Runs the given command and compares characters written by the command to the output of running the characters through the parser and serializing the actions back `to_ansi`. If the parser works correctly the output should be the same.

## Limitations

- The parser is based on the implementation https://github.com/haberman/vtparse/ and based on a state machine which precedes Unicode. As such it does not have state transitions for Unicode characters. Rather, it will output them as `:ignore` actions. In case unicode characters are used inside escape sequences, the parser will likely not be able to handle them correctly.

- The state machine does not expose all input characters to the implementation in relationship to the `DSC` (Device Control String) sequences. In particular the "Final Character" is swallowed by the statemachine from https://www.vt100.net/emu/dec_ansi_parser. To circumvent this limitation, I have modified the parser to expose the final character as intermediate_chars to the `:hook` action.

- The parser only outputs full `actions`. So triggering an event for the `ESC` key doesn't work (as expected).

- The parser does not emit actions for commands which are 'interrupted' by another command."

- The parser does not explain any of the actions.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/coezbek/vtparser.
