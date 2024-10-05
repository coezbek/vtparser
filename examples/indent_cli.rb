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

  if $DEBUG && (action_type != :print || !(ch =~ /\P{Cc}/))
    puts "\r\n"
    puts action.inspect
    puts "\r\n"
    # sleep 5
  end

  print to_output
end

begin
  PTY.spawn(command) do |stdout_and_stderr, stdin, pid|

    # Input Thread
    input_thread = Thread.new do

      STDIN.raw do |io|
        loop do
          break if pid.nil?
          begin
            if io.wait_readable(0.1)
              data = io.read_nonblock(1024)
              stdin.write data
            end
          rescue IO::WaitReadable
            # No input available right now
          rescue EOFError
            break
          rescue Errno::EIO
            break
          end
        end
      end
    end

    # Pipe stdout and stderr to the parser
    begin

      begin
        winsize = $stdout.winsize
      rescue Errno::ENOTTY
        winsize = [0, 120] # Default to 120 columns
      end
      # Ensure the child process has the proper window size, because 
      #  - tools such as yarn use it to identify tty mode
      #  - some tools use it to determine the width of the terminal for formatting
      stdout_and_stderr.winsize = [winsize.first, winsize.last - line_indent_length]
      
      stdout_and_stderr.each_char do |char|

        char = block.call(char) if block_given?
        next if char.nil?
        
        # puts Action.inspect_char(char) + "\r\n"  
        # Pass to parser
        parser.parse(char)

      end
    rescue Errno::EIO
      # End of output
    end

    # Wait for the child process to exit
    Process.wait(pid)
    pid = nil
    input_thread.join  
  end

rescue PTY::ChildExited => e
  puts "The child process exited: #{e}"
end

# Clear and reset the cursor to the start of the line
puts "\e[2K\e[1G"
