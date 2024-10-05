require 'pty'
require 'rainbow/refinement' # for colorizing output
using Rainbow
require_relative '../lib/vtparser'

#
# 'swap_colors_cli.rb' - Example for vtparser
#
# This example demonstrates how to use VTParser to swap colors (red to green, green to red) of a simple tty program.
#
# Run with `ruby swap_colors_cli.rb <command>`, where <command> is the command you want to run.
#

# Get the command from ARGV
command = ARGV.join(' ')
if command.empty?
  puts "Usage: ruby swap_colors_cli.rb '<command>'"
  exit 1
end

# VT100 color codes for red and green
COLOR_RED = "\e[31m"
COLOR_GREEN = "\e[32m"
RESET_COLOR = "\e[0m"

# VTParser block to swap red and green colors in the output
parser = VTParser.new do |action, ch, intermediate_chars, params|
  to_output = VTParser::to_ansi(action, ch, intermediate_chars, params)

  case to_output
  when COLOR_RED
    print COLOR_GREEN # Swap red to green
  when COLOR_GREEN
    print COLOR_RED # Swap green to red
  else
    print to_output # Default behavior for other output
  end
end

parser.spawn(command)
