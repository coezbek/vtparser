require_relative '../lib/vtparser'
require 'pty'
require 'tty-prompt' # for winsize call below

#
# This example demonstrates how to use the VTParser to analyze the VT100 escape sequences outputted by a program.
#

# Get the command from ARGV
command = ARGV.join(' ')
if command.empty?
  puts "Usage: ruby indent_cli.rb '<command>'"
  exit 1
end

# Instantiate the parser with a block to handle actions
parser = VTParser.new do |action|
  puts action.inspect + "\r\n"
end

parser.spawn(command)
