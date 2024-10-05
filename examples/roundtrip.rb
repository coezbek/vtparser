require_relative '../lib/vtparser'
require 'pty'
require 'tty-prompt' # for winsize call below

COLOR_GREEN = "\e[32m"
RESET_COLOR = "\e[0m"

#
# This example checks if the output of VTParser is identical to the data fed into parser.
#
# Examples you can try:
#
# ruby roundtrip.rb 'vim'  # Exit with :q
# ruby roundtrip.rb 'ls -la'
# ruby roundtrip.rb 'less' # Exit with q
# ruby roundtrip.rb 'top'
# Screensavers:
# ruby roundtrip.rb 'cmatrix' # sudo apt-get install cmatrix
# ruby roundtrip.rb 'neo'     # install from https://github.com/st3w/neo
#    Note: that upon termination a mismatch will be detected, because neo will cancel an on-going CSI sequence by sending an ESC character.
# 

# Get the command from ARGV
command = ARGV.join(' ')
if command.empty?
  puts "Usage: ruby indent_cli.rb '<command>'"
  exit 1
end

captured = []
previous_actions = []
previous_characters = []

# Instantiate the parser with a block to handle actions
parser = VTParser.new do |action|
  
  from_parser = action.to_ansi
  from_parser.each_char.with_index do |char, i|
    if captured.empty?
      puts "ERROR: Parser has extra character after parsing: #{char.inspect}\r\n"
      exit(1)
    end
    if char != captured.first
      puts "\r\n"
      puts "ERROR: Parser output does not match input with index #{i}: #{char.inspect} != #{captured.first.inspect}\r\n"
      puts "Current captured characters: #{captured.inspect}\r\n"
      puts "Current parser output: #{from_parser.inspect}\r\n"
      puts "Previous characters: #{previous_characters.join.inspect}\r\n"

      puts "\r\n"
      previous_actions.each_with_index do |prev_action, i|
        puts "Previous action -#{(previous_actions.length - i).to_s.rjust(2)}: #{prev_action.inspect}\r\n"
      end
      puts "Current  action    : #{action.inspect}\r\n"
      
      exit(1)
    end
    matched_char = captured.shift
    previous_characters << matched_char
    if previous_characters.size > 20
      previous_characters.shift
    end

    print "#{COLOR_GREEN}.#{RESET_COLOR}"
  end

  previous_actions << action
  if previous_actions.size > 20
    previous_actions.shift
  end

end

parser.spawn(command) do |char|

  captured << char

  next char
end

puts
puts "#{COLOR_GREEN}SUCCESS: Parser output matches input.#{RESET_COLOR}"

