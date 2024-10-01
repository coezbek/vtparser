require_relative '../lib/vtparser'

# Instantiate the parser with a block to handle actions
parser = VTParser.new do |action, ch, intermediate_chars, params|

  # For this minimal example, we'll just turn everything back strings to print
  print VTParser::to_ansi(action, ch, intermediate_chars, params)

end

# Sample input containing ANSI escape sequences (red text, bold text)
input = "\e[31mHello, \e[1mWorld!\e[0m\n"

# Parse the input
parser.parse(input)