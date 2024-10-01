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
# A simple loading animation is included in `examples/spinner.rb`: `ruby indent_cli.rb 'ruby spinner.rb'`
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
parser = VTParser.new do |action, ch, intermediate_chars, params|
  print line_indent if first_line
  first_line = false

  to_output = VTParser::to_ansi(action, ch, intermediate_chars, params)

  # Handle newlines, carriage returns, and cursor movement 
  case action
  when :print, :execute, :put, :osc_put
    if ch == "\n" || ch == "\r"
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

  print to_output
end

#
# Spawn the given command using PTY::spawn, and connect pipes.
#
begin
  PTY.spawn(command) do |stdout_and_stderr, stdin, pid|

    # Start separate thread to pipe stdin to the child process
    Thread.new do     
      while pid != nil
        stdin.write(STDIN.readpartial(1024)) # Requires user to press enter!
      end
    rescue => e
      puts "Error: #{e}"
      exit(0)
    end

    # Pipe stdout and stderr to the parser
    begin
      # Ensure the child process has a window size, because tools such as yarn use it to identify tty mode
      stdout_and_stderr.winsize = $stdout.winsize 

      stdout_and_stderr.each_char do |char|

        parser.parse(char)

      end
    rescue Errno::EIO
      # End of output
    end

    # Wait for the child process to exit
    Process.wait(pid)
    pid = nil
    exit_status = $?.exitstatus
    result = exit_status == 0

    # Clear the line, reset the cursor to the start of the line
    print "\e[2K\e[1G"
  end

rescue PTY::ChildExited => e
  puts "The child process exited: #{e}"
end