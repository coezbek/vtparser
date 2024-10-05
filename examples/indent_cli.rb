require 'pty'
require "tty-prompt" # for winsize call below
require 'rainbow/refinement' # for colorizing output
using Rainbow
require_relative '../lib/vtparser'

#
# 'indent_cli.rb' - Example for vtparser
#
# This example demonstrates how to use the VTParser to indent the output of simple (!) tty programs 
# with colorized or animated output.
#
# Run with `ruby indent_cli.rb <command>`` where <command> is the command you want to run.
#
# Two simple examples are included:
# - A simple spinner animation is included in `examples/spinner.rb`: `ruby indent_cli.rb 'ruby spinner.rb'`
# - A simple progress bar animation is included in `examples/progress.rb`: `ruby indent_cli.rb 'ruby progress.rb'`
#

# Get the command from ARGV
command = ARGV.join(' ')
if command.empty?
  puts "Usage: ruby indent_cli.rb '<command>'"
  exit 1
end

line_indent = '   ▐  '.yellow
line_indent_length = 6

#
# Use VTParser to process the VT100 escape sequences outputted by nested program and prepend the line_indent text.
#
first_line = true
parser = VTParser.new do |action|

  ch = action.ch
  intermediate_chars = action.intermediate_chars
  params = action.params
  action_type = action.action_type
  to_output = action.to_ansi

  if true
    print line_indent if first_line
    first_line = false

    if $DEBUG && (action_type != :print || !(ch =~ /\P{Cc}/))
      puts action.inspect
    end

    # Handle newlines, carriage returns, and cursor movement 
    case action_type
    when :print, :execute, :put, :osc_put
      if ch == "\r" # || ch == "\n" 
        print ch
        print line_indent
        next
      end
    when :csi_dispatch
      if to_output == "\e[2K" # Clear line
        print "\e[2K"
        print line_indent
        next
      else
        if ch == 'G' # Cursor movement to column
          print "\e[#{parser.params[0] + line_indent_length}G"
          next
        end
      end
    end
  end

  if $DEBUG && (action_type != :print || !(ch =~ /\P{Cc}/))
    puts "\r\n"
    puts action.inspect
    puts "\r\n"
    # sleep 5
  end

  print to_output
end

parser.spawn(command)

# Clear and reset the cursor to the start of the line
puts "\e[2K\e[1G"
